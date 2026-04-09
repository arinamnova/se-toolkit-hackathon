import httpx
from fastapi import APIRouter, Depends
from sqlmodel import select
from sqlalchemy.ext.asyncio import AsyncSession

from cat_manager.database import get_session
from cat_manager.models import Pet, VetVisit
from cat_manager.schemas import ChatIn, ChatOut
from cat_manager.settings import settings

router = APIRouter()


@router.post("/chat", response_model=ChatOut)
async def chat(
    chat_in: ChatIn,
    session: AsyncSession = Depends(get_session),
):
    # Build context from pet data if pet_id is provided
    context = ""
    if chat_in.pet_id:
        result = await session.execute(select(Pet).where(Pet.id == chat_in.pet_id))
        pet = result.scalar_one_or_none()
        if pet:
            visits_result = await session.execute(
                select(VetVisit)
                .where(VetVisit.pet_id == pet.id)
                .order_by(VetVisit.visit_date.desc())
                .limit(5)
            )
            visits = list(visits_result.scalars().all())
            visit_history = "\n".join(
                [f"- {v.visit_date}: {v.notes or 'Regular checkup'}" for v in visits]
            )
            context = f"Pet info: {pet.name} is a {pet.age or 'unknown'} year old {pet.breed or pet.species}."
            if visit_history:
                context += f"\nRecent vet visits:\n{visit_history}"
            if pet.health_notes:
                context += f"\nHealth notes: {pet.health_notes}"
            context += "\n\n"

    system_prompt = (
        f"{context}You are a helpful and friendly pet care assistant. "
        f"Answer the user's question based on the pet information above. "
        f"If no pet info is available, still answer general pet care questions. "
        f"Be concise and helpful."
    )

    async with httpx.AsyncClient() as client:
        response = await client.post(
            f"{settings.llm_api_base_url}/chat/completions",
            headers={
                "Authorization": f"Bearer {settings.llm_api_key}",
                "Content-Type": "application/json",
            },
            json={
                "model": settings.llm_api_model,
                "messages": [
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": chat_in.message},
                ],
            },
            timeout=30.0,
        )
        response.raise_for_status()
        data = response.json()
        answer = data["choices"][0]["message"]["content"]

    return ChatOut(response=answer)
