"""add notification_error to capsules

Revision ID: c4d9e21a7f30
Revises: 8fddaf303368
Create Date: 2026-07-05

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'c4d9e21a7f30'
down_revision: Union[str, Sequence[str], None] = '8fddaf303368'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.add_column('capsules', sa.Column('notification_error', sa.Text(), nullable=True))


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_column('capsules', 'notification_error')
