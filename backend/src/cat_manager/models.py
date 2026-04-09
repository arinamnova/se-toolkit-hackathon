from datetime import date, datetime

from sqlmodel import Field, Relationship, SQLModel


class Pet(SQLModel, table=True):
    id: int | None = Field(default=None, primary_key=True)
    name: str
    species: str
    breed: str | None = None
    age: float | None = None
    health_notes: str | None = None
    created_at: datetime = Field(default_factory=datetime.now)

    vet_visits: list["VetVisit"] = Relationship(back_populates="pet", cascade_delete=True)


class VetVisit(SQLModel, table=True):
    id: int | None = Field(default=None, primary_key=True)
    pet_id: int = Field(foreign_key="pet.id", ondelete="CASCADE")
    visit_date: date
    notes: str | None = None
    created_at: datetime = Field(default_factory=datetime.now)

    pet: Pet = Relationship(back_populates="vet_visits")
