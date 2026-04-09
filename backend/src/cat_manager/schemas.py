from datetime import date, datetime

from pydantic import BaseModel


class PetIn(BaseModel):
    name: str
    species: str
    breed: str | None = None
    age: float | None = None
    health_notes: str | None = None


class PetUpdate(BaseModel):
    name: str | None = None
    species: str | None = None
    breed: str | None = None
    age: float | None = None
    health_notes: str | None = None


class PetOut(BaseModel):
    id: int
    name: str
    species: str
    breed: str | None
    age: float | None
    health_notes: str | None
    created_at: datetime

    model_config = {"from_attributes": True}


class VetVisitIn(BaseModel):
    visit_date: date
    notes: str | None = None


class VetVisitOut(BaseModel):
    id: int
    pet_id: int
    visit_date: date
    notes: str | None
    created_at: datetime

    model_config = {"from_attributes": True}


class ChatIn(BaseModel):
    message: str
    pet_id: int | None = None


class ChatOut(BaseModel):
    response: str
