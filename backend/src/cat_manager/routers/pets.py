from fastapi import APIRouter, Depends, HTTPException
from sqlmodel import select
from sqlalchemy.ext.asyncio import AsyncSession

from cat_manager.database import get_session
from cat_manager.models import Pet
from cat_manager.schemas import PetIn, PetOut, PetUpdate

router = APIRouter()


@router.get("/", response_model=list[PetOut])
async def list_pets(session: AsyncSession = Depends(get_session)):
    result = await session.execute(select(Pet))
    return list(result.scalars().all())


@router.post("/", response_model=PetOut, status_code=201)
async def create_pet(pet: PetIn, session: AsyncSession = Depends(get_session)):
    db_pet = Pet.model_validate(pet)
    session.add(db_pet)
    await session.commit()
    await session.refresh(db_pet)
    return db_pet


@router.get("/{pet_id}", response_model=PetOut)
async def get_pet(pet_id: int, session: AsyncSession = Depends(get_session)):
    result = await session.execute(select(Pet).where(Pet.id == pet_id))
    return result.scalar_one()


@router.put("/{pet_id}", response_model=PetOut)
async def update_pet(
    pet_id: int,
    pet_in: PetUpdate,
    session: AsyncSession = Depends(get_session),
):
    result = await session.execute(select(Pet).where(Pet.id == pet_id))
    db_pet = result.scalar_one_or_none()
    if not db_pet:
        raise HTTPException(status_code=404, detail="Pet not found")
    update_data = pet_in.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(db_pet, key, value)
    session.add(db_pet)
    await session.commit()
    await session.refresh(db_pet)
    return db_pet


@router.delete("/{pet_id}", status_code=204)
async def delete_pet(pet_id: int, session: AsyncSession = Depends(get_session)):
    result = await session.execute(select(Pet).where(Pet.id == pet_id))
    db_pet = result.scalar_one_or_none()
    if not db_pet:
        raise HTTPException(status_code=404, detail="Pet not found")
    await session.delete(db_pet)
    await session.commit()
