"""
Base model definitions supporting Pydantic with fallback to standard dataclasses.
Provides unified serialization and deserialization across runtime environments.
"""

import dataclasses
from typing import Any, Dict, List, Type, TypeVar, Optional

T = TypeVar("T", bound="SerializableModel")

try:
    from pydantic import BaseModel as _PydanticBase, Field as _Field
    PYDANTIC_AVAILABLE = True
except ImportError:
    PYDANTIC_AVAILABLE = False
    _PydanticBase = object  # type: ignore
    _Field = None  # type: ignore


class SerializableModel:
    """
    Unified serialization interface for data models.
    """

    def to_dict(self) -> Dict[str, Any]:
        """
        Serialize model instance to a standard Python dictionary.
        """
        if PYDANTIC_AVAILABLE and isinstance(self, _PydanticBase):
            if hasattr(self, "model_dump"):
                return self.model_dump()
            elif hasattr(self, "dict"):
                return self.dict()
        if dataclasses.is_dataclass(self):
            result = {}
            for field in dataclasses.fields(self):
                val = getattr(self, field.name)
                if isinstance(val, SerializableModel):
                    result[field.name] = val.to_dict()
                elif isinstance(val, list):
                    result[field.name] = [
                        item.to_dict() if isinstance(item, SerializableModel) else item
                        for item in val
                    ]
                else:
                    result[field.name] = val
            return result
        if hasattr(self, "__dict__"):
            return {
                k: (v.to_dict() if isinstance(v, SerializableModel) else v)
                for k, v in self.__dict__.items()
                if not k.startswith("_")
            }
        return {}

    @classmethod
    def from_dict(cls: Type[T], data: Dict[str, Any]) -> T:
        """
        Instantiate model from a dictionary.
        """
        if PYDANTIC_AVAILABLE and issubclass(cls, _PydanticBase):
            if hasattr(cls, "model_validate"):
                return cls.model_validate(data)
            elif hasattr(cls, "parse_obj"):
                return cls.parse_obj(data)
        if dataclasses.is_dataclass(cls):
            field_map = {f.name: f for f in dataclasses.fields(cls)}
            filtered = {}
            for k, v in data.items():
                if k in field_map:
                    f = field_map[k]
                    f_type = f.type
                    if isinstance(v, dict) and hasattr(f_type, "from_dict"):
                        filtered[k] = f_type.from_dict(v)
                    elif isinstance(v, list) and v and isinstance(v[0], dict):
                        if hasattr(f_type, "__args__") and f_type.__args__ and hasattr(f_type.__args__[0], "from_dict"):
                            elem_cls = f_type.__args__[0]
                            filtered[k] = [
                                elem_cls.from_dict(item) if isinstance(item, dict) else item
                                for item in v
                            ]
                        else:
                            filtered[k] = v
                    else:
                        filtered[k] = v
            return cls(**filtered)
        return cls(**data)


if PYDANTIC_AVAILABLE:
    class BaseModel(_PydanticBase, SerializableModel):  # type: ignore
        """
        Base model leveraging Pydantic when available.
        """
        pass

    Field = _Field

else:
    class BaseModel(SerializableModel):  # type: ignore
        """
        Fallback Base model using dataclasses when Pydantic is not installed.
        """
        def __init_subclass__(cls, **kwargs: Any) -> None:
            super().__init_subclass__(**kwargs)
            dataclasses.dataclass(cls)

    def Field(default: Any = ..., **kwargs: Any) -> Any:  # type: ignore
        if default is ...:
            return dataclasses.field(**kwargs)
        return dataclasses.field(default=default, **kwargs)
