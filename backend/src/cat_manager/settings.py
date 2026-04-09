from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    app_name: str = "Pet Manager Service"
    debug: bool = False
    cors_origins: list[str] = ["*"]
    db_host: str = "postgres"
    db_port: int = 5432
    db_name: str = "db-cat-manager"
    db_user: str = "postgres"
    db_password: str = "postgres"
    llm_api_key: str = ""
    llm_api_base_url: str = "http://qwen-code-api:8080/v1"
    llm_api_model: str = "coder-model"

    @property
    def database_url(self) -> str:
        return f"postgresql+asyncpg://{self.db_user}:{self.db_password}@{self.db_host}:{self.db_port}/{self.db_name}"

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


settings = Settings()
