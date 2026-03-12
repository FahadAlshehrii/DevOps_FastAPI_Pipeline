from fastapi import FastAPI

app = FastAPI()

@app.get("/")
def read_root():
    return {"message": "Hello from Azure! My CI/CD pipeline worked."}

@app.get("/health")
def health_check():
    return {"status": "healthy"}

@app.get("/fahad")
def read_root():
    return {"message": "hi this is me fahad."}


