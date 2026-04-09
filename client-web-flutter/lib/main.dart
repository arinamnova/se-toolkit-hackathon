import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(const CatManagerApp());

class CatManagerApp extends StatelessWidget {
  const CatManagerApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '🦎 Pet Manager',
      theme: ThemeData(
        colorSchemeSeed: Colors.orange,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🦎 Pet Manager'),
      ),
      body: IndexedStack(
        index: _tab,
        children: const [PetManagerScreen(), ChatScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.pets), label: 'My Pets'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline), label: 'Ask AI'),
        ],
      ),
    );
  }
}

// ===================== PET MANAGER =====================

class PetManagerScreen extends StatefulWidget {
  const PetManagerScreen({super.key});
  @override
  State<PetManagerScreen> createState() => _PetManagerScreenState();
}

class _PetManagerScreenState extends State<PetManagerScreen> {
  List<Map<String, dynamic>> _pets = [];
  Map<int, Map<String, dynamic>?> _lastVisits = {};
  bool _loading = true;
  int? _selectedPetId;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    await _loadPets();
  }

  Future<void> _loadPets() async {
    try {
      final resp = await http.get(Uri.parse('/pets'));
      if (resp.statusCode == 200 && resp.headers['content-type']?.contains('json') == true) {
        final pets = (jsonDecode(resp.body) as List).cast<Map<String, dynamic>>();
        setState(() {
          _pets = pets;
          if (_pets.isNotEmpty && (_selectedPetId == null || !pets.any((p) => p['id'] == _selectedPetId))) {
            _selectedPetId = pets.first['id'] as int;
          }
          _loading = false;
        });
        // Load last visit for each pet
        for (final pet in pets) {
          await _loadLastVisit(pet['id'] as int);
        }
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadLastVisit(int petId) async {
    try {
      final resp = await http.get(Uri.parse('/pets/$petId/vet-visits'));
      if (resp.statusCode == 200 && resp.headers['content-type']?.contains('json') == true) {
        final visits = (jsonDecode(resp.body) as List).cast<Map<String, dynamic>>();
        setState(() {
          _lastVisits[petId] = visits.isNotEmpty ? visits.first : null;
        });
      }
    } catch (_) {}
  }

  Map<String, dynamic>? get _selectedPet =>
      _selectedPetId != null
          ? _pets.firstWhere((p) => p['id'] == _selectedPetId, orElse: () => {})
          : null;

  Future<void> _editPet(Map<String, dynamic> pet) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PetFormScreen(pet: pet)),
    );
    if (result == true) _loadAll();
  }

  Future<void> _addPet() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PetFormScreen()),
    );
    if (result == true) _loadAll();
  }

  Future<void> _deletePet(int id, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Pet'),
        content: Text('Are you sure you want to delete $name?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true) {
      await http.delete(Uri.parse('/pets/$id'));
      setState(() => _selectedPetId = null);
      _loadAll();
    }
  }

  Future<void> _recordVetVisit(int petId, String petName) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VetVisitFormScreen(petId: petId, petName: petName),
      ),
    );
    if (result == true) {
      await _loadLastVisit(petId);
    }
  }

  Future<void> _viewVetVisits(int petId, String petName) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VetVisitListScreen(petId: petId, petName: petName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pets.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🐾', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text('No pets yet!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('Add your first pet to get started.'),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _addPet,
              icon: const Icon(Icons.add),
              label: const Text('Add Pet'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      );
    }

    // Quick switcher dropdown at the top
    final selectedPet = _selectedPet;
    final lastVisit = _lastVisits[_selectedPetId];

    return Column(
      children: [
        // Dropdown card
        Card(
          margin: const EdgeInsets.all(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.pets, size: 24),
                    const SizedBox(width: 8),
                    const Text('Quick Switch', style: TextStyle(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _addPet,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Pet'),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: _selectedPetId,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: _pets.map((pet) {
                    return DropdownMenuItem<int>(
                      value: pet['id'] as int,
                      child: Text(pet['name'] as String),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedPetId = v),
                ),
              ],
            ),
          ),
        ),

        // Selected pet detail card
        if (selectedPet != null)
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        child: Text(
                          selectedPet['name'].substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            fontSize: 20,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selectedPet['name'] as String,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            Text([
                              selectedPet['breed'] as String?,
                              selectedPet['species'] as String?,
                              selectedPet['age'] != null ? '${selectedPet['age']}y' : null,
                            ].whereType<String>().join(' · ')),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: () => _editPet(selectedPet)),
                          IconButton(icon: const Icon(Icons.delete_outline), onPressed: () => _deletePet(selectedPet['id'] as int, selectedPet['name'] as String)),
                        ],
                      ),
                    ],
                  ),
                  if ((selectedPet['health_notes'] as String?)?.isNotEmpty == true) ...[
                    const Divider(),
                    const Text('Health Notes:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(selectedPet['health_notes'] as String),
                  ],
                  const Divider(),
                  Row(
                    children: [
                      const Icon(Icons.medical_services, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        lastVisit != null
                            ? 'Last vet visit: ${DateTime.parse(lastVisit!['visit_date'] as String).toLocal().toString().split(' ')[0]}'
                            : 'No vet visits recorded',
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => _recordVetVisit(selectedPet['id'] as int, selectedPet['name'] as String),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Record'),
                      ),
                      TextButton(
                        onPressed: () => _viewVetVisits(selectedPet['id'] as int, selectedPet['name'] as String),
                        child: const Text('History'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

        // Other pets list
        Expanded(
          child: _pets.length > 1
              ? ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _pets.length,
                  itemBuilder: (ctx, i) {
                    final pet = _pets[i];
                    if (pet['id'] == _selectedPetId) return const SizedBox.shrink();
                    final visit = _lastVisits[pet['id']];
                    return Card(
                      child: ListTile(
                        onTap: () => setState(() => _selectedPetId = pet['id'] as int),
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                          child: Text(
                            (pet['name'] as String).substring(0, 1).toUpperCase(),
                            style: TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer),
                          ),
                        ),
                        title: Text(pet['name'] as String),
                        subtitle: Text([
                          pet['breed'] as String?,
                          pet['species'] as String?,
                          pet['age'] != null ? '${pet['age']}y' : null,
                          visit != null ? 'Last visit: ${DateTime.parse(visit['visit_date'] as String).toLocal().toString().split(' ')[0]}' : null,
                        ].whereType<String>().join(' · ')),
                        trailing: const Icon(Icons.chevron_right),
                      ),
                    );
                  },
                )
              : const Center(
                  child: Text('Use the dropdown above to switch pets.', style: TextStyle(color: Colors.grey)),
                ),
        ),
      ],
    );
  }
}

// ===================== PET FORM =====================

class PetFormScreen extends StatefulWidget {
  final Map<String, dynamic>? pet;
  const PetFormScreen({super.key, this.pet});
  @override
  State<PetFormScreen> createState() => _PetFormScreenState();
}

class _PetFormScreenState extends State<PetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _speciesCtrl;
  late final TextEditingController _breedCtrl;
  late final TextEditingController _ageCtrl;
  late final TextEditingController _healthNotesCtrl;
  bool _saving = false;
  bool get _isEdit => widget.pet != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.pet?['name'] as String? ?? '');
    _speciesCtrl = TextEditingController(text: widget.pet?['species'] as String? ?? 'cat');
    _breedCtrl = TextEditingController(text: widget.pet?['breed'] as String? ?? '');
    _ageCtrl = TextEditingController(text: widget.pet?['age']?.toString() ?? '');
    _healthNotesCtrl = TextEditingController(text: widget.pet?['health_notes'] as String? ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _speciesCtrl.dispose(); _breedCtrl.dispose();
    _ageCtrl.dispose(); _healthNotesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final body = jsonEncode({
      'name': _nameCtrl.text.trim(),
      'species': _speciesCtrl.text.trim(),
      'breed': _breedCtrl.text.trim().isEmpty ? null : _breedCtrl.text.trim(),
      'age': _ageCtrl.text.trim().isEmpty ? null : double.tryParse(_ageCtrl.text.trim()),
      'health_notes': _healthNotesCtrl.text.trim().isEmpty ? null : _healthNotesCtrl.text.trim(),
    });
    try {
      final http.Response resp;
      if (_isEdit) {
        resp = await http.put(Uri.parse('/pets/${widget.pet!['id']}'), headers: {'Content-Type': 'application/json'}, body: body);
      } else {
        resp = await http.post(Uri.parse('/pets'), headers: {'Content-Type': 'application/json'}, body: body);
      }
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        if (mounted) Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${resp.statusCode}')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Pet' : 'Add Pet')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Name *', border: OutlineInputBorder()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              textCapitalization: TextCapitalization.words),
            const SizedBox(height: 16),
            TextFormField(controller: _speciesCtrl, decoration: const InputDecoration(labelText: 'Species *', border: OutlineInputBorder(), hintText: 'cat, dog, rabbit...'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null),
            const SizedBox(height: 16),
            TextFormField(controller: _breedCtrl, decoration: const InputDecoration(labelText: 'Breed', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextFormField(controller: _ageCtrl, decoration: const InputDecoration(labelText: 'Age', border: OutlineInputBorder()),
              keyboardType: const TextInputType.numberWithOptions(decimal: true)),
            const SizedBox(height: 16),
            TextFormField(controller: _healthNotesCtrl, decoration: const InputDecoration(labelText: 'Health Notes', border: OutlineInputBorder(), alignLabelWithHint: true), maxLines: 3),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_isEdit ? 'Save Changes' : 'Add Pet'),
            )),
          ],
        ),
      ),
    );
  }
}

// ===================== VET VISIT FORM =====================

class VetVisitFormScreen extends StatefulWidget {
  final int petId;
  final String petName;
  const VetVisitFormScreen({super.key, required this.petId, required this.petName});
  @override
  State<VetVisitFormScreen> createState() => _VetVisitFormScreenState();
}

class _VetVisitFormScreenState extends State<VetVisitFormScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();
  late final TextEditingController _notesCtrl;
  bool _saving = false;

  @override
  void initState() { super.initState(); _notesCtrl = TextEditingController(); }
  @override
  void dispose() { _notesCtrl.dispose(); super.dispose(); }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2000), lastDate: DateTime.now().add(const Duration(days: 365)));
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final dateStr = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
    final body = jsonEncode({
      'visit_date': dateStr,
      'notes': _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    });
    try {
      final resp = await http.post(Uri.parse('/pets/${widget.petId}/vet-visits'), headers: {'Content-Type': 'application/json'}, body: body);
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Vet visit recorded for ${widget.petName}!')));
          Navigator.pop(context, true);
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${resp.statusCode}')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Vet Visit — ${widget.petName}')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Visit Date'),
                subtitle: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: _pickDate,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(controller: _notesCtrl, decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder(), alignLabelWithHint: true, hintText: 'e.g. Annual checkup, vaccination, healthy...'), maxLines: 4),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.medical_services),
              label: Text(_saving ? 'Recording...' : 'Record Visit'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            )),
          ],
        ),
      ),
    );
  }
}

// ===================== VET VISIT LIST =====================

class VetVisitListScreen extends StatefulWidget {
  final int petId;
  final String petName;
  const VetVisitListScreen({super.key, required this.petId, required this.petName});
  @override
  State<VetVisitListScreen> createState() => _VetVisitListScreenState();
}

class _VetVisitListScreenState extends State<VetVisitListScreen> {
  List<Map<String, dynamic>> _visits = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _loadVisits(); }

  Future<void> _loadVisits() async {
    setState(() => _loading = true);
    try {
      final resp = await http.get(Uri.parse('/pets/${widget.petId}/vet-visits'));
      if (resp.statusCode == 200) {
        setState(() { _visits = (jsonDecode(resp.body) as List).cast<Map<String, dynamic>>(); _loading = false; });
      }
    } catch (_) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Vet Visits — ${widget.petName}')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _visits.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🏥', style: TextStyle(fontSize: 48)),
                      SizedBox(height: 16),
                      Text('No vet visits recorded yet.'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _visits.length,
                  itemBuilder: (ctx, i) {
                    final v = _visits[i];
                    final date = DateTime.parse(v['visit_date'] as String);
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.medical_services),
                        title: Text('${date.day}/${date.month}/${date.year}'),
                        subtitle: v['notes'] != null ? Text(v['notes'] as String) : null,
                      ),
                    );
                  },
                ),
    );
  }
}

// ===================== CHAT SCREEN =====================

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _messages = <Map<String, String>>[];
  bool _loading = false;
  int? _selectedPetId;
  String? _selectedPetName;
  String? _selectedPetInfo;
  List<Map<String, dynamic>> _pets = [];

  @override
  void initState() { super.initState(); _loadPets(); }

  Future<void> _loadPets() async {
    try {
      final resp = await http.get(Uri.parse('/pets'));
      if (resp.statusCode == 200) {
        setState(() {
          _pets = (jsonDecode(resp.body) as List).cast<Map<String, dynamic>>();
          if (_pets.isNotEmpty) {
            _selectPet(_pets.first);
          }
        });
      }
    } catch (_) {}
  }

  void _selectPet(Map<String, dynamic> pet) {
    _selectedPetId = pet['id'] as int;
    _selectedPetName = pet['name'] as String;
    _selectedPetInfo = [
      pet['breed'],
      pet['species'],
      pet['age'] != null ? '${pet['age']}y' : null,
    ].whereType<String>().join(' · ');
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _loading) return;
    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _loading = true;
    });
    _controller.clear();
    try {
      final Map<String, dynamic> body = {'message': text};
      if (_selectedPetId != null) body['pet_id'] = _selectedPetId;
      final resp = await http.post(Uri.parse('/chat'), headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
      final data = jsonDecode(resp.body);
      setState(() { _messages.add({'role': 'bot', 'content': data['response'] ?? 'No response'}); });
    } catch (e) {
      setState(() { _messages.add({'role': 'bot', 'content': 'Error: $e'}); });
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_pets.isEmpty) {
      return const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('💬', style: TextStyle(fontSize: 48)),
          SizedBox(height: 16),
          Text('Add a pet first!', style: TextStyle(fontSize: 16)),
          SizedBox(height: 8),
          Text('Go to the My Pets tab and add your pet.'),
        ]),
      );
    }

    return Column(
      children: [
        // Pet selector with info
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.pets, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedPetId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Chat about',
                        border: InputBorder.none,
                      ),
                      items: _pets.map((pet) {
                        return DropdownMenuItem<int>(
                          value: pet['id'] as int,
                          child: Text(pet['name'] as String),
                        );
                      }).toList(),
                      onChanged: (v) {
                        final pet = _pets.firstWhere((p) => p['id'] == v);
                        setState(() => _selectPet(pet));
                      },
                    ),
                  ),
                  if (_selectedPetInfo != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(_selectedPetInfo!, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onPrimaryContainer)),
                    ),
                ],
              ),
            ),
          ),
        ),
        // Messages
        Expanded(
          child: _messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🐱 Ask about ${_selectedPetName ?? 'your pet'}!', style: const TextStyle(fontSize: 16, color: Colors.grey)),
                      const SizedBox(height: 8),
                      const Text('e.g. "When should I take them to the vet?"', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _messages.length,
                  itemBuilder: (ctx, i) {
                    final m = _messages[i];
                    final isUser = m['role'] == 'user';
                    return Align(
                      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Card(
                        color: isUser ? Theme.of(context).colorScheme.primaryContainer : null,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Text(m['content'] ?? ''),
                        ),
                      ),
                    );
                  },
                ),
        ),
        // Input
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  onSubmitted: (_) => _send(),
                  decoration: const InputDecoration(hintText: 'Ask about your pet...', border: OutlineInputBorder()),
                  enabled: !_loading,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _loading ? null : _send,
                child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Send'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
