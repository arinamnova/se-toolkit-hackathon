# Cat Manager

A web application for managing pet information, veterinary visits, and providing AI-powered chat assistance for pet owners.

## Demo

<!-- Add screenshots of your product here -->
![Dashboard Screenshot](docs/screenshots/dashboard.png)
![Chat Interface](docs/screenshots/chat.png)

## Product Context

### End Users

Pet owners who need to track their pets' health records, veterinary appointments, and get quick answers to pet care questions.

### Problem

Pet owners struggle to keep track of their pets' medical history, vaccination schedules, and veterinary visits. They also lack a centralized platform to get AI-assisted advice on pet care.

### Solution

Cat Manager provides a unified platform to:
- Register and manage pet profiles with medical records
- Schedule and track veterinary visits
- Get AI-powered chat assistance for pet-related questions

## Features

### Implemented

- [x] Pet profile management (add, view, update pets)
- [x] Veterinary visit scheduling and history
- [x] AI-powered chat assistant for pet care questions
- [x] Web-based user interface
- [x] RESTful API backend
- [x] Database for persistent storage
- [x] Docker containerization for all services
- [x] Deployment configuration

### Not Yet Implemented

- [ ] Push notifications for upcoming vet visits
- [ ] Multi-user family accounts
- [ ] Integration with veterinary clinics' systems
- [ ] Mobile app (Flutter web version available)

## Usage

### For End Users

1. Access the deployed web application through your browser
2. Register a new account or log in
3. Add your pets and their information
4. Schedule veterinary visits
5. Use the chat feature to ask questions about pet care

### For Developers

```bash
# Clone the repository
git clone https://github.com/arinamnova/se-toolkit-hackathon.git
cd se-toolkit-hackathon

# Copy environment variables
cp .env.docker.example .env

# Start all services with Docker Compose
docker-compose up -d
```

The application will be available at the configured ports (default: backend on port 8000, web client on port 3000).

## Deployment

### Prerequisites

- **OS**: Ubuntu 24.04 LTS (or compatible Linux distribution)
- **Required Software**:
  - Docker (version 24.0 or higher)
  - Docker Compose (version 2.20 or higher)
  - Git

### Step-by-Step Deployment

1. **Install Docker and Docker Compose** (if not already installed):

   ```bash
   # Update package list
   sudo apt update

   # Install prerequisites
   sudo apt install -y ca-certificates curl gnupg

   # Add Docker's official GPG key
   sudo install -m 0755 -d /etc/apt/keyrings
   curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
   sudo chmod a+r /etc/apt/keyrings/docker.gpg

   # Add Docker repository
   echo \
     "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
     $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
     sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

   # Install Docker
   sudo apt update
   sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
   ```

2. **Clone the Repository**:

   ```bash
   git clone https://github.com/arinamnova/se-toolkit-hackathon.git
   cd se-toolkit-hackathon
   ```

3. **Configure Environment Variables**:

   ```bash
   cp .env.docker.example .env
   # Edit .env file with your specific configuration
   nano .env
   ```

4. **Start Services**:

   ```bash
   docker-compose up -d
   ```

5. **Verify Deployment**:

   ```bash
   docker-compose ps
   docker-compose logs -f
   ```

6. **Access the Application**:

   - Web client: `http://<your-server-ip>:3000`
   - Backend API: `http://<your-server-ip>:8000/docs`

### Services Architecture

- **Backend**: FastAPI-based REST API with PostgreSQL database
- **Database**: PostgreSQL for persistent data storage
- **Web Client**: Flutter-based web application
- **Reverse Proxy**: Caddy for SSL and routing (optional)

### Troubleshooting

- Check logs: `docker-compose logs <service-name>`
- Restart services: `docker-compose restart`
- Rebuild containers: `docker-compose up -d --build`
