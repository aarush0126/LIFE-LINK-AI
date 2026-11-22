from __future__ import annotations

from math import ceil
from typing import TypeVar

from fastapi import Query
from pydantic import BaseModel
from sqlalchemy import Select, func, select
from sqlalchemy.orm import Session

T = TypeVar("T")


class Pagination(BaseModel):
    page: int = 1
    page_size: int = 25

    @classmethod
    def dependency(
        cls,
        page: int = Query(1, ge=1),
        page_size: int = Query(25, ge=1, le=100),
    ) -> Pagination:
        return cls(page=page, page_size=page_size)


def paginate(
    session: Session,
    statement: Select[tuple[T]],
    pagination: Pagination,
) -> tuple[list[T], dict[str, int]]:
    count_statement = select(func.count()).select_from(statement.order_by(None).subquery())
    total = int(session.scalar(count_statement) or 0)
    rows = list(
        session.scalars(
            statement.offset((pagination.page - 1) * pagination.page_size).limit(
                pagination.page_size
            )
        )
    )
    return rows, {
        "page": pagination.page,
        "page_size": pagination.page_size,
        "total": total,
        "pages": ceil(total / pagination.page_size) if total else 0,
    }


def page_response(items: list[dict[str, object]], meta: dict[str, int]) -> dict[str, object]:
    return {"items": items, "pagination": meta}
