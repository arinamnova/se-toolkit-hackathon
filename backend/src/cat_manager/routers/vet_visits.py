from fastapi import APIRouter, Depends
from sqlmodel import select
from sqlalchemy.ext.asyncio import AsyncSession

from cat_manager.database import get_session
from cat_manager.models import VetVisit
from cat_manager.schemas import VetVisitIn, VetVisitOut

router = APIRouter()


@router.get("/{pet_id}/vet-visits", response_model=list[VetVisitOut])
async def list_visits(pet_id: int, session: AsyncSession = Depends(get_session)):
    result = await session.execute(
        select(VetVisit)
        .where(VetVisit.pet_id == pet_id)
        .order_by(VetVisit.visit_date.desc())
    )
    return list(result.scalars().all())


@router.post("/{pet_id}/vet-visits", response_model=VetVisitOut, status_code=201)
async def create_visit(
    pet_id: int,
    visit: VetVisitIn,
    session: AsyncSession = Depends(get_session),
):
    db_visit = VetVisit(pet_id=pet_id, **visit.model_dump())
    session.add(db_visit)
    await session.commit()
    await session.refresh(db_visit)
    return db_visit
