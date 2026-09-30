import os
import datetime
import jwt
from fastapi import FastAPI, HTTPException, Depends
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from dotenv import load_dotenv

# Load secret key from .env file
load_dotenv()
SECRET_KEY = os.getenv("SECRET_KEY", "nexus_secret_key_12345")
ALGORITHM = "HS256"

app = FastAPI()

# Allow Flutter (Web, Desktop, Mobile) to connect to FastAPI
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

security = HTTPBearer()

# ==============================================================================
# 1. JSON DESERIALIZATION MODEL
# FastAPI uses Pydantic to automatically convert (deserialize) incoming JSON
# from the HTTP request body into this Python object.
# ==============================================================================
class LoginRequest(BaseModel):
    username: str
    password: str


# ==============================================================================
# 2. JWT TOKEN GENERATION
# Creates a digitally signed token containing the user identity (claims).
# ==============================================================================
def create_jwt_token(username: str) -> str:
    # Set the token to expire in 1 hour
    expiration = datetime.datetime.now(datetime.timezone.utc) + datetime.timedelta(hours=1)
    
    # Payload: the data stored inside the token
    payload = {
        "sub": username,     # "sub" stands for subject (the user's identity)
        "exp": expiration    # "exp" stands for expiration time
    }
    
    # Sign the token using our secret key and the HS256 algorithm
    token = jwt.encode(payload, SECRET_KEY, algorithm=ALGORITHM)
    return token


# ==============================================================================
# 3. JWT TOKEN VERIFICATION
# Extracts the token from the "Authorization: Bearer <token>" header and verifies it.
# ==============================================================================
def verify_jwt_token(credentials: HTTPAuthorizationCredentials = Depends(security)) -> str:
    token = credentials.credentials
    try:
        # Decode and verify the cryptographic signature using our SECRET_KEY
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        return payload["sub"]  # Return the username stored in the token
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token has expired. Please log in again.")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid token. Verification failed.")


# ==============================================================================
# 4. API ENDPOINTS
# ==============================================================================

# POST: Authenticates user credentials and returns a JWT
@app.post("/api/login")
def login(data: LoginRequest):
    # Check credentials against simple mock data (admin / 123456)
    if data.username == "admin" and data.password == "123456":
        # Create a new JWT for this user
        token = create_jwt_token(data.username)
        
        # SERIALIZATION: FastAPI converts this Python dictionary to a JSON response
        return {
            "access_token": token,
            "token_type": "bearer"
        }
    
    raise HTTPException(status_code=401, detail="Invalid username or password")


# GET: Protected endpoint requiring a valid JWT token
@app.get("/api/protected-data")
def get_protected_data(username: str = Depends(verify_jwt_token)):
    # SERIALIZATION: FastAPI converts this Python dictionary to a JSON response
    return {
        "message": f"Hello, {username}! You successfully accessed protected data.",
        "secret_data": "NexusAuth: Classified server data 42"
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="127.0.0.1", port=8000, reload=True)