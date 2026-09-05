from geoalchemy2 import Geometry
from sqlalchemy import Column, Float, Integer, SmallInteger, String
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.sql import func

from app.db.database import Base


class LocalVotacao(Base):
    __tablename__ = "locais_votacao"

    id = Column(UUID(as_uuid=True), primary_key=True, server_default=func.gen_random_uuid())
    ano_eleicao = Column(Integer, nullable=False)
    nr_zona = Column(SmallInteger, nullable=False)
    nr_secao = Column(SmallInteger, nullable=False)
    nome_local = Column(String(255), nullable=False)
    endereco = Column(String(255), nullable=True)
    bairro = Column(String(100), nullable=True)
    nr_cep = Column(String(20), nullable=True)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    geom = Column(Geometry(geometry_type="POINT", srid=4326), nullable=True)
