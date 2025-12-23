# main.py — CORRECTED VERSION
import os
import uuid
import json  
import razorpay
from twilio.rest import Client
import random
import hmac
import hashlib
from datetime import datetime, timedelta
from fastapi import Request,FastAPI, HTTPException, Depends, UploadFile, File, Form, status,Body
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordBearer
from jose import jwt, JWTError
from datetime import datetime
from database import get_db_connection
from security import create_access_token, get_password_hash, verify_password
from security import SECRET_KEY, ALGORITHM
from pydantic import BaseModel
from typing import Optional, List
from pydantic import Field
from models import UserCreate, UserLogin, AddressCreate, B2CRegister, OrderCreate , PhoneRequest, VerifyOtpRequest,normalize_phone, ResetPasswordRequest ,CreatePaymentRequest,VerifyPaymentRequest,ReturnCreate  
from dotenv import load_dotenv
from dotenv import load_dotenv





load_dotenv()
TWILIO_ACCOUNT_SID = os.getenv("TWILIO_ACCOUNT_SID")
TWILIO_AUTH_TOKEN = os.getenv("TWILIO_AUTH_TOKEN")
TWILIO_VERIFY_SERVICE_SID = "VA2b0a240ab58b4db3c500fec2f6ae344e"  # You need to create this in Twilio Console
client = Client(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN)

# Initialize RazorPay client
RAZORPAY_KEY_ID = os.getenv("RAZORPAY_KEY_ID")
RAZORPAY_KEY_SECRET = os.getenv("RAZORPAY_KEY_SECRET")

razorpay_client = razorpay.Client(auth=(RAZORPAY_KEY_ID, RAZORPAY_KEY_SECRET))


otp_store = {}


app = FastAPI(title="backendapi")

# CORS Configuration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

oauth2_scheme = OAuth2PasswordBearer(tokenUrl="auth/login")

# Ensure upload directories exist
for _dir in ("uploads", "uploads/b2b/gst", "uploads/b2b/license"):
    os.makedirs(_dir, exist_ok=True)


def get_current_user(token: str = Depends(oauth2_scheme)):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email: str = payload.get("sub")
        if email is None:
            raise credentials_exception

    except JWTError:
        raise credentials_exception

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    cursor.execute("SELECT id FROM auth_users WHERE email = %s", (email,))
    user = cursor.fetchone()
    conn.close()

    if user is None:
        raise credentials_exception
    
    return user["id"] # Return the user_id

@app.post("/auth/send-verification")
async def send_verification(payload: PhoneRequest):
    phone = normalize_phone(payload.phone)  # 🔥 ADD THIS

    otp = str(random.randint(100000, 999999))
    otp_store[phone] = {
        "otp": otp,
        "expires_at": datetime.now() + timedelta(minutes=10),
        "verified": False
    }

    client.messages.create(
        body=f"Your verification code is: {otp}",
        from_=os.getenv("TWILIO_PHONE_NUMBER"),
        to=phone
    )

    return {"message": "OTP sent successfully"}


@app.post("/auth/verify-otp")
async def verify_otp(payload: VerifyOtpRequest):
    phone = normalize_phone(payload.phone)   # ✅ keep normalization
    otp = payload.otp

    # ✅ Decide OTP key safely
    if payload.type == "reset":
        key = f"reset_{phone}"
    else:
        key = phone  # signup / b2b signup

    if key not in otp_store:
        raise HTTPException(400, "No OTP requested for this phone")

    record = otp_store[key]

    if datetime.now() > record["expires_at"]:
        del otp_store[key]
        raise HTTPException(400, "OTP expired")

    if record["otp"] != otp:
        raise HTTPException(400, "Invalid OTP")

    record["verified"] = True
    return {
        "success": True,
        "message": "Phone verified successfully"
    }



@app.post("/auth/forgot-password/request")
async def forgot_password_request(payload: PhoneRequest):
    phone = normalize_phone(payload.phone)
    """Send OTP for password reset (check if phone exists in DB)"""
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    # Check if phone exists in auth_users
    cursor.execute("SELECT id FROM auth_users WHERE phone_number = %s", (phone,))
    if not cursor.fetchone():
        raise HTTPException(404, "Phone number not registered")
    
    # Send OTP (same logic as send_verification)
    otp = str(random.randint(100000, 999999))
    otp_store[f"reset_{phone}"] = {
        "otp": otp,
        "expires_at": datetime.now() + timedelta(minutes=10)
    }
    
    message = client.messages.create(
        body=f"Your password reset code is: {otp}",
        from_=os.getenv("TWILIO_PHONE_NUMBER"),
        to=phone
    )
    
    return {"success":  True, "message": "Reset OTP sent"}

@app.post("/auth/reset-password")
async def reset_password(payload: ResetPasswordRequest):
    phone = normalize_phone(payload.phone)
    email = payload.email.lower()
    otp = payload.otp
    new_password = payload.new_password

    key = f"reset_{phone}"

    if key not in otp_store:
        raise HTTPException(400, "No reset request found")

    record = otp_store[key]

    if datetime.now() > record["expires_at"]:
        del otp_store[key]
        raise HTTPException(400, "OTP expired")

    if record["otp"] != otp:
        raise HTTPException(400, "Invalid OTP")

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    cursor.execute(
        "SELECT id FROM auth_users WHERE email = %s AND phone_number = %s",
        (email, phone)
    )
    user = cursor.fetchone()

    if not user:
        raise HTTPException(
            status_code=404,
            detail="No account found for this email and phone number"
        )

    hashed_pw = get_password_hash(new_password[:72])

    cursor.execute(
        "UPDATE auth_users SET password_hash = %s WHERE id = %s",
        (hashed_pw, user["id"])
    )
    conn.commit()

    del otp_store[key]

    return {"success": True, "message": "Password reset successful"}


# ============================ AUTH ============================
@app.post("/auth/signup")
async def signup(user: UserCreate):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute("SELECT id FROM auth_users WHERE email = %s", (user.email,))
        if cursor.fetchone():
            raise HTTPException(status_code=400, detail="Email already registered")

        user_id = str(uuid.uuid4())
        truncated_pw = (user.password or "")[:72]
        hashed_pw = get_password_hash(truncated_pw)

        cursor.execute("""
    INSERT INTO auth_users 
    (id, email, password_hash, full_name, phone_number, raw_user_meta_data)
    VALUES (%s, %s, %s, %s, %s, %s)
    """, (user_id, user.email, hashed_pw, user.full_name, user.phone_number, "{}"))

        conn.commit()
        token = create_access_token(
            {"sub": user.email}, 
            user_id=user_id,
            user_type="b2c"  # Default to B2C for regular signup
        )
        
        # We now create the token based on the user's email, which is required by get_current_user
        token = create_access_token({"sub": user.email}) 
        return {"access_token": token, "token_type": "bearer", "user_id": user_id}
    finally:
        cursor.close()
        conn.close()

        
@app.post("/auth/login")
async def login(form: UserLogin):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        # First, check auth_users table
        cursor.execute("SELECT id, password_hash, email FROM auth_users WHERE email = %s", (form.email,))
        user = cursor.fetchone()
        
        if not user:
            raise HTTPException(401, "Incorrect email or password")
        
        # Verify password
        provided_pw = (form.password or "")[:72]
        if not verify_password(provided_pw, user["password_hash"]):
            raise HTTPException(401, "Incorrect email or password")
        
        # Determine if user is B2B or B2C
        user_type = "b2c"  # default
        
        # Check if user exists in b2b_applications
        cursor.execute("SELECT id, status FROM b2b_applications WHERE user_id = %s", (user["id"],))
        b2b_app = cursor.fetchone()
        
        if b2b_app:
            if b2b_app["status"] != "approved":
                raise HTTPException(403, f"B2B account is {b2b_app['status']}. Please wait for approval.")
            user_type = "b2b"
        
        # Create token with user type
        token = create_access_token({
            "sub": form.email,
            "user_id": user["id"],
            "user_type": user_type
        })
        
        return {
            "access_token": token,
            "token_type": "bearer",
            "user_type": user_type
        }
    finally:
        cursor.close()
        conn.close()

# ============================ B2C SIGNUP (Normal User) ============================
@app.post("/auth/register/b2c")
async def register_b2c(payload: B2CRegister):
    # This is for regular customer signup. It uses the same main signup logic.
    user_in = UserCreate(
        email=payload.email, password=payload.password,
        full_name=payload.full_name, phone_number=payload.phone_number,
    )
    
    # Call signup to create user
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        # Check if email exists
        cursor.execute("SELECT id FROM auth_users WHERE email = %s", (payload.email,))
        if cursor.fetchone():
            raise HTTPException(status_code=400, detail="Email already registered")
            
        # Normalize phone number before OTP check
        phone = normalize_phone(payload.phone_number)

        otp_entry = otp_store.get(phone)
        if not otp_entry or not otp_entry.get("verified"):
            raise HTTPException(status_code=400, detail="Phone number not verified")
   

        user_id = str(uuid.uuid4())
        truncated_pw = (payload.password or "")[:72]
        hashed_pw = get_password_hash(truncated_pw)

            # Insert into auth_users table
        cursor.execute("""
       INSERT INTO auth_users 
       (id, email, password_hash, full_name, phone_number, raw_user_meta_data)
        VALUES (%s, %s, %s, %s, %s, %s)
       """, (user_id, payload.email, hashed_pw, payload.full_name, phone, "{}"))

        # Create address if provided
        address_id = None
        if payload.address:
            address_id = str(uuid.uuid4())
            cursor.execute("""
                INSERT INTO addresses (id, street, city, postal_code, country, user_id)
                VALUES (%s, %s, %s, %s, %s, %s)
            """, (address_id, payload.address.street, payload.address.city, 
                  payload.address.postal_code, payload.address.country, user_id))

            cursor.execute("""
                INSERT INTO user_addresses (id, user_id, address_id, name, is_default)
                VALUES (UUID(), %s, %s, %s, %s)
            """, (user_id, address_id, payload.address.name or "Home", payload.address.is_default or False))

        # Insert into b2c_applications table
        cursor.execute("""
            INSERT INTO b2c_applications 
            (id, full_name, phone_number, email, address_id)
            VALUES (%s, %s, %s, %s, %s)
        """, (user_id, payload.full_name, phone, payload.email, address_id))
        
        conn.commit()
        
        # Clean up OTP record after successful registration
        otp_store.pop(phone, None)

        
        # Create token with all required claims
        token = create_access_token(
            {"sub": payload.email}, 
            user_id=user_id,
            user_type="b2c"
        )
        
        return {
            "access_token": token, 
            "token_type": "bearer", 
            "user_id": user_id,
            "message": "B2C registration successful"
        }
        
    except Exception as e:
        if conn: conn.rollback()
        raise HTTPException(status_code=500, detail=f"Registration failed: {e}")
    finally:
        if cursor: cursor.close()
        if conn: conn.close()
# ============================ B2B SIGNUP WITH DOCUMENTS ============================
@app.post("/auth/register/b2b")
async def register_b2b(
    email: str = Form(...), 
    password: str = Form(...),
    business_name: str = Form(...), 
    gstin: str = Form(...),
    pan: str = Form(...), 
    phone_number: str = Form(...),
    address: str = Form(None), 
    gst_certificate: UploadFile = File(...),
    business_license: UploadFile = File(...)
):
    conn = None
    cursor = None

    try:
        # ✅ Normalize phone FIRST
        phone = normalize_phone(phone_number)

        # ✅ OTP VERIFICATION FIRST (before DB writes)
        otp_entry = otp_store.get(phone)
        if not otp_entry or not otp_entry.get("verified"):
            raise HTTPException(status_code=400, detail="Phone number not verified")

        conn = get_db_connection()
        cursor = conn.cursor()

        # ✅ Check if email already exists
        cursor.execute("SELECT id FROM auth_users WHERE email = %s", (email,))
        if cursor.fetchone():
            raise HTTPException(status_code=400, detail="Email already registered")

        # ✅ Create user
        user_id = str(uuid.uuid4())
        hashed_pw = get_password_hash(password[:72])

        cursor.execute("""
            INSERT INTO auth_users 
            (id, email, password_hash, phone_number, raw_user_meta_data)
            VALUES (%s, %s, %s, %s, %s)
        """, (user_id, email, hashed_pw, phone, "{}"))

        # ✅ Save documents
        os.makedirs("uploads/b2b/gst", exist_ok=True)
        os.makedirs("uploads/b2b/license", exist_ok=True)

        gst_filename = f"{uuid.uuid4().hex}_{os.path.basename(gst_certificate.filename)}"
        license_filename = f"{uuid.uuid4().hex}_{os.path.basename(business_license.filename)}"

        gst_path = os.path.join("uploads", "b2b", "gst", gst_filename)
        license_path = os.path.join("uploads", "b2b", "license", license_filename)

        with open(gst_path, "wb") as f:
            f.write(await gst_certificate.read())

        with open(license_path, "wb") as f:
            f.write(await business_license.read())

        # ✅ Address handling
        address_id = None
        if address:
            addr_obj = json.loads(address)

            if addr_obj.get("street"):
                address_id = str(uuid.uuid4())
                cursor.execute("""
                    INSERT INTO addresses (id, street, city, postal_code, country, user_id)
                    VALUES (%s, %s, %s, %s, %s, %s)
                """, (
                    address_id,
                    addr_obj.get("street"),
                    addr_obj.get("city"),
                    addr_obj.get("postal_code"),
                    addr_obj.get("country"),
                    user_id
                ))

                cursor.execute("""
                    INSERT INTO user_addresses (id, user_id, address_id, name, is_default)
                    VALUES (%s, %s, %s, %s, %s)
                """, (str(uuid.uuid4()), user_id, address_id, "Business Address", True))

        # ✅ Insert B2B application
        b2b_app_id = str(uuid.uuid4())
        now = datetime.now()

        cursor.execute("""
            INSERT INTO b2b_applications
            (id, user_id, business_name, gstin, pan, email, phone_number,
             gst_certificate_url, business_license_url, status, created_at, address_id)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """, (
            b2b_app_id,
            user_id,
            business_name,
            gstin,
            pan,
            email,
            phone,
            gst_path,
            license_path,
            "pending_approval",
            now,
            address_id
        ))

        conn.commit()

        # ✅ Remove OTP after success
        otp_store.pop(phone, None)

        # ✅ Create token
        token = create_access_token(
            {"sub": email},
            user_id=user_id,
            user_type="b2b"
        )

        return {
            "message": "B2B Application Submitted Successfully",
            "application_id": b2b_app_id,
            "user_id": user_id,
            "access_token": token,
            "token_type": "bearer"
        }

    except HTTPException:
        raise
    except Exception as e:
        if conn:
            conn.rollback()
        print("🔥 B2B REGISTER ERROR:", repr(e))
        raise HTTPException(status_code=500, detail="B2B registration failed")
    finally:
        if cursor:
            cursor.close()
        if conn:
            conn.close()

# ============================ ADDRESS CRUD ============================

@app.post("/users/addresses")
async def create_address(address: AddressCreate, current_user_id: str = Depends(get_current_user)):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        address_id = str(uuid.uuid4())
        if address.is_default:
            cursor.execute("UPDATE user_addresses SET is_default = 0 WHERE user_id = %s", (current_user_id,))
        cursor.execute("""
            INSERT INTO addresses (id, street, city, postal_code, country, user_id)
            VALUES (%s, %s, %s, %s, %s, %s)
        """, (address_id, address.street, address.city, address.postal_code, address.country, current_user_id))
        cursor.execute("""
            INSERT INTO user_addresses (id, user_id, address_id, name, is_default)
            VALUES (UUID(), %s, %s, %s, %s)
        """, (current_user_id, address_id, address.name, address.is_default))
        conn.commit()
        return {"message": "Address added", "address_id": address_id}
    finally:
        if cursor: cursor.close()
        if conn: conn.close()

@app.put("/users/addresses/{user_address_id}")
async def update_address(user_address_id: str, address: AddressCreate, current_user_id: str = Depends(get_current_user)):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("SELECT address_id FROM user_addresses WHERE id = %s AND user_id = %s", (user_address_id, current_user_id))
        row = cursor.fetchone()
        if not row:
            raise HTTPException(status_code=404, detail="Address not found")
        address_id = row[0]
        if address.is_default:
            cursor.execute("UPDATE user_addresses SET is_default = 0 WHERE user_id = %s", (current_user_id,))
        cursor.execute("""
            UPDATE addresses SET street = %s, city = %s, postal_code = %s, country = %s
            WHERE id = %s AND user_id = %s
        """, (address.street, address.city, address.postal_code, address.country, address_id, current_user_id))
        cursor.execute("""
            UPDATE user_addresses SET name = %s, is_default = %s
            WHERE id = %s AND user_id = %s
        """, (address.name, address.is_default, user_address_id, current_user_id))
        conn.commit()
        return {"message": "Address updated"}
    finally:
        if cursor: cursor.close()
        if conn: conn.close()

@app.delete("/users/addresses/{user_address_id}")
async def delete_address(user_address_id: str, current_user_id: str = Depends(get_current_user)):
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("DELETE FROM user_addresses WHERE id = %s AND user_id = %s", (user_address_id, current_user_id))
        conn.commit()
        if cursor.rowcount == 0:
            raise HTTPException(status_code=404, detail="Address not found or not owned by user")
        return {"message": "Deleted"}
    finally:
        if cursor: cursor.close()
        if conn: conn.close()

@app.get("/users/addresses")
async def list_addresses(current_user_id: str = Depends(get_current_user)):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    try:
        cursor.execute("""
            SELECT 
                ua.id AS user_address_id, ua.name, ua.is_default,
                a.id, a.street, a.city, a.postal_code, a.country
            FROM user_addresses ua JOIN addresses a ON ua.address_id = a.id
            WHERE ua.user_id = %s ORDER BY ua.created_at DESC
        """, (current_user_id,))
        return {"data": cursor.fetchall()}
    finally:
        cursor.close()
        conn.close()

# ============================ USER PROFILE (GET /users/me) ============================

@app.get("/users/me")
async def get_me(token: str = Depends(oauth2_scheme)):
    """
    Returns the logged-in user's complete profile information.
    Detects B2B or B2C automatically based on the token payload.
    """
    # Validate token
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email = payload.get("sub")
        user_id = payload.get("user_id")
        user_type = payload.get("user_type")
        if not email or not user_id:
            raise HTTPException(401, "Invalid token")
    except JWTError:
        raise HTTPException(401, "Invalid or expired token")

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    try:
        user_info = {
            "user_id": user_id,
            "email": email,
            "user_type": user_type or "b2c"
        }

        if user_type == "b2b":
            # Fetch from b2b_applications table
            cursor.execute("""
                SELECT 
                    business_name,
                    email,
                    phone_number,
                    gstin,
                    pan,
                    created_at
                FROM b2b_applications
                WHERE user_id = %s
            """, (user_id,))
            row = cursor.fetchone()
            
            if row:
                user_info["full_name"] = row["business_name"]  # Use business name as display name
                user_info["business_name"] = row["business_name"]
                user_info["email"] = row["email"]
                user_info["phone_number"] = row["phone_number"]
                user_info["gstin"] = row["gstin"]
                user_info["pan"] = row["pan"]
                user_info["created_at"] = row["created_at"]
                
                # Also get from auth_users for consistency
                cursor.execute("""
                    SELECT full_name, created_at as auth_created_at 
                    FROM auth_users 
                    WHERE id = %s
                """, (user_id,))
                auth_row = cursor.fetchone()
                if auth_row and auth_row["full_name"]:
                    user_info["full_name"] = auth_row["full_name"]  # Prefer personal name if available
                user_info["auth_created_at"] = auth_row["auth_created_at"] if auth_row else row["created_at"]
        
        else:
            # Fetch from b2c_applications table
            cursor.execute("""
                SELECT 
                    full_name,
                    email,
                    phone_number,
                    created_at
                FROM b2c_applications
                WHERE id = %s
            """, (user_id,))
            row = cursor.fetchone()
            
            if row:
                user_info["full_name"] = row["full_name"]
                user_info["email"] = row["email"]
                user_info["phone_number"] = row["phone_number"]
                user_info["created_at"] = row["created_at"]
                
                # Also get from auth_users for consistency
                cursor.execute("""
                    SELECT created_at as auth_created_at 
                    FROM auth_users 
                    WHERE id = %s
                """, (user_id,))
                auth_row = cursor.fetchone()
                user_info["auth_created_at"] = auth_row["auth_created_at"] if auth_row else row["created_at"]

        # If no data found in application tables, fallback to auth_users
        if not row:
            cursor.execute("""
                SELECT 
                    full_name,
                    email,
                    phone_number,
                    created_at as auth_created_at
                FROM auth_users 
                WHERE id = %s
            """, (user_id,))
            auth_data = cursor.fetchone()
            
            if auth_data:
                user_info["full_name"] = auth_data["full_name"] or email.split('@')[0]
                user_info["email"] = auth_data["email"]
                user_info["phone_number"] = auth_data["phone_number"]
                user_info["created_at"] = auth_data["auth_created_at"]
                user_info["auth_created_at"] = auth_data["auth_created_at"]
                
                # Set default values for B2B fields
                if user_type == "b2b":
                    user_info["gstin"] = ""
                    user_info["pan"] = ""
                    user_info["business_name"] = ""
        return user_info

    finally:
        cursor.close()
        conn.close()
# ============================ DELETE USER ACCOUNT ============================
@app.delete("/users/me")
async def delete_user(current_user_id: str = Depends(get_current_user)):
    """
    Deletes the user account and all associated data.
    """
    conn = get_db_connection()
    cursor = conn.cursor()
    
    try:
        # Start transaction
        cursor.execute("START TRANSACTION")
        
        # First, check if user exists in b2b_applications
        cursor.execute("SELECT id FROM b2b_applications WHERE user_id = %s", (current_user_id,))
        b2b_app = cursor.fetchone()
        
        if b2b_app:
            # Delete from b2b_applications table
            cursor.execute("DELETE FROM b2b_applications WHERE user_id = %s", (current_user_id,))
        else:
            # Delete from b2c_applications table
            cursor.execute("DELETE FROM b2c_applications WHERE id = %s", (current_user_id,))
        
        # Delete user addresses
        cursor.execute("DELETE FROM user_addresses WHERE user_id = %s", (current_user_id,))
        cursor.execute("DELETE FROM addresses WHERE user_id = %s", (current_user_id,))
        
        # Finally delete from auth_users
        cursor.execute("DELETE FROM auth_users WHERE id = %s", (current_user_id,))
        
        conn.commit()
        
        return {"message": "Account deleted successfully"}
        
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"Failed to delete account: {e}")
    finally:
        cursor.close()
        conn.close()


@app.put("/users/me")
async def update_user_profile(
    update_data: dict = Body(...),
    current_user_id: str = Depends(get_current_user)
):
    """
    Update user profile information.
    """
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    try:
        # First check user type from token
        try:
            # Get token from header
            from fastapi import Request
            request = Request.scope.get("request")
            token = request.headers.get("authorization").split(" ")[1]
            payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
            user_type = payload.get("user_type", "b2c")
        except:
            # Fallback: check if user exists in b2b_applications table
            cursor.execute("SELECT id FROM b2b_applications WHERE user_id = %s", (current_user_id,))
            b2b_app = cursor.fetchone()
            user_type = "b2b" if b2b_app else "b2c"
        
        # Update auth_users table
        auth_updates = []
        auth_values = []
        
        # Map update fields to database columns
        field_mapping = {
            'full_name': 'full_name',
            'phone_number': 'phone_number',
            
        }
        
        for field, db_field in field_mapping.items():
            if field in update_data:
                auth_updates.append(f"{db_field} = %s")
                auth_values.append(update_data[field])
        
        if auth_updates:
            auth_values.append(current_user_id)
            auth_query = f"UPDATE auth_users SET {', '.join(auth_updates)} WHERE id = %s"
            cursor.execute(auth_query, auth_values)
        
        # Update specific application table
        if user_type == "b2b":
            # Update b2b_applications table
            b2b_updates = []
            b2b_values = []
            
            b2b_fields = ['business_name', 'gstin', 'pan', 'phone_number', 'email']
            for field in b2b_fields:
                if field in update_data:
                    b2b_updates.append(f"{field} = %s")
                    b2b_values.append(update_data[field])
            
            if b2b_updates:
                b2b_values.append(current_user_id)
                b2b_query = f"UPDATE b2b_applications SET {', '.join(b2b_updates)} WHERE user_id = %s"
                cursor.execute(b2b_query, b2b_values)
        else:
            # Update b2c_applications table
            b2c_updates = []
            b2c_values = []
            
            b2c_fields = ['full_name', 'phone_number', 'email']
            for field in b2c_fields:
                if field in update_data:
                    b2c_updates.append(f"{field} = %s")
                    b2c_values.append(update_data[field])
            
            if b2c_updates:
                b2c_values.append(current_user_id)
                b2c_query = f"UPDATE b2c_applications SET {', '.join(b2c_updates)} WHERE id = %s"
                cursor.execute(b2c_query, b2c_values)
        
        conn.commit()
        
        return {"message": "Profile updated successfully"}
        
    except Exception as e:
        conn.rollback()
        raise HTTPException(status_code=500, detail=f"Update failed: {e}")
    finally:
        cursor.close()
        conn.close()
# ============================ PRODUCT ENDPOINTS (View Only) ============================

# Get all products with filtering
@app.get("/products")
async def get_products(
    category: Optional[str] = None,
    min_price: Optional[float] = None,
    max_price: Optional[float] = None,
    status: Optional[str] = "Published",
    limit: int = 50,
    offset: int = 0,
    user_type: str = "b2c"  # b2c or b2b
):
    """
    Get products with filtering. User type determines which price to show.
    """
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    try:
        # Base query - REMOVED 'rating, reviews' as they don't exist in products table
        query = """
            SELECT 
                id, name, category, description, status, stock, image,
                created_at, updated_at,
                b2c_price, b2b_price, 
                b2c_active_offer, b2b_active_offer,
                b2c_offer_price, b2b_offer_price,
                b2c_discount, b2b_discount,
                b2c_offer_start_date, b2c_offer_end_date,
                b2b_offer_start_date, b2b_offer_end_date,
                compare_at_price
                -- rating, reviews REMOVED: These columns don't exist in products table
            FROM products WHERE 1=1
        """
        params = []
        
        # Apply filters
        if category and category.lower() != "all":
            query += " AND category = %s"
            params.append(category)
        
        if min_price is not None:
            if user_type == "b2c":
                query += " AND b2c_price >= %s"
            else:
                query += " AND b2b_price >= %s"
            params.append(min_price)
        
        if max_price is not None:
            if user_type == "b2c":
                query += " AND b2c_price <= %s"
            else:
                query += " AND b2b_price <= %s"
            params.append(max_price)
        
        if status:
            query += " AND status = %s"
            params.append(status)
        
        # Add pagination
        query += " ORDER BY created_at DESC LIMIT %s OFFSET %s"
        params.extend([limit, offset])
        
        cursor.execute(query, params)
        products = cursor.fetchall()
        
        # Get review counts for each product
        for product in products:
            # Get review count from product_reviews table
            cursor.execute("""
                SELECT 
                    COUNT(*) as review_count,
                    AVG(rating) as avg_rating
                FROM product_reviews 
                WHERE product_id = %s
            """, (product["id"],))
            review_stats = cursor.fetchone()
            
            # Add rating and reviews to product dynamically
            product["reviews"] = review_stats["review_count"] if review_stats else 0
            product["rating"] = round(review_stats["avg_rating"], 2) if review_stats and review_stats["avg_rating"] else 0
            
            # Calculate current price based on user type and active offers
            current_time = datetime.now()
            
            if user_type == "b2c":
                # Check if offer is active
                is_offer_active = (
                    product["b2c_active_offer"] and 
                    product["b2c_offer_price"] > 0 and
                    (product["b2c_offer_start_date"] is None or product["b2c_offer_start_date"] <= current_time) and
                    (product["b2c_offer_end_date"] is None or product["b2c_offer_end_date"] >= current_time)
                )
                
                if is_offer_active:
                    product["current_price"] = product["b2c_offer_price"]
                    if product["b2c_price"] > 0:
                        product["discount_percentage"] = round(
                            (product["b2c_price"] - product["b2c_offer_price"]) / product["b2c_price"] * 100, 2
                        )
                    else:
                        product["discount_percentage"] = 0
                else:
                    product["current_price"] = product["b2c_price"]
                    product["discount_percentage"] = product["b2c_discount"] or 0
                    
                product["original_price"] = product["b2c_price"]
                    
            else:  # b2b
                # Check if offer is active
                is_offer_active = (
                    product["b2b_active_offer"] and 
                    product["b2b_offer_price"] > 0 and
                    (product["b2b_offer_start_date"] is None or product["b2b_offer_start_date"] <= current_time) and
                    (product["b2b_offer_end_date"] is None or product["b2b_offer_end_date"] >= current_time)
                )
                
                if is_offer_active:
                    product["current_price"] = product["b2b_offer_price"]
                    if product["b2b_price"] > 0:
                        product["discount_percentage"] = round(
                            (product["b2b_price"] - product["b2b_offer_price"]) / product["b2b_price"] * 100, 2
                        )
                    else:
                        product["discount_percentage"] = 0
                else:
                    product["current_price"] = product["b2b_price"]
                    product["discount_percentage"] = product["b2b_discount"] or 0
                    
                product["original_price"] = product["b2b_price"]
        
        return {"products": products, "count": len(products)}
    
    finally:
        cursor.close()
        conn.close()

# Get single product
@app.get("/products/{product_id}")
async def get_product(product_id: str, user_type: str = "b2c"):
    """
    Get a single product by ID.
    """
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    try:
        cursor.execute("""
            SELECT 
                id, name, category, description, status, stock, image,
                created_at, updated_at,
                b2c_price, b2b_price, 
                b2c_active_offer, b2b_active_offer,
                b2c_offer_price, b2b_offer_price,
                b2c_discount, b2b_discount,
                b2c_offer_start_date, b2c_offer_end_date,
                b2b_offer_start_date, b2b_offer_end_date,
                compare_at_price
            FROM products WHERE id = %s
        """, (product_id,))
        product = cursor.fetchone()
        
        if not product:
            raise HTTPException(status_code=404, detail="Product not found")
        
        # Get review stats
        cursor.execute("""
            SELECT 
                COUNT(*) as review_count,
                AVG(rating) as avg_rating
            FROM product_reviews 
            WHERE product_id = %s
        """, (product_id,))
        review_stats = cursor.fetchone()
        
        product["reviews"] = review_stats["review_count"] if review_stats else 0
        product["rating"] = round(review_stats["avg_rating"], 2) if review_stats and review_stats["avg_rating"] else 0
        
        # Format response based on user_type
        current_time = datetime.now()
        
        if user_type == "b2c":
            # Check if offer is active
            is_offer_active = (
                product["b2c_active_offer"] and 
                product["b2c_offer_price"] > 0 and
                (product["b2c_offer_start_date"] is None or product["b2c_offer_start_date"] <= current_time) and
                (product["b2c_offer_end_date"] is None or product["b2c_offer_end_date"] >= current_time)
            )
            
            if is_offer_active:
                product["current_price"] = product["b2c_offer_price"]
                if product["b2c_price"] > 0:
                    product["discount_percentage"] = round(
                        (product["b2c_price"] - product["b2c_offer_price"]) / product["b2c_price"] * 100, 2
                    )
                else:
                    product["discount_percentage"] = 0
            else:
                product["current_price"] = product["b2c_price"]
                product["discount_percentage"] = product["b2c_discount"] or 0
                
            product["original_price"] = product["b2c_price"]
            
        else:  # b2b
            # Check if offer is active
            is_offer_active = (
                product["b2b_active_offer"] and 
                product["b2b_offer_price"] > 0 and
                (product["b2b_offer_start_date"] is None or product["b2b_offer_start_date"] <= current_time) and
                (product["b2b_offer_end_date"] is None or product["b2b_offer_end_date"] >= current_time)
            )
            
            if is_offer_active:
                product["current_price"] = product["b2b_offer_price"]
                if product["b2b_price"] > 0:
                    product["discount_percentage"] = round(
                        (product["b2b_price"] - product["b2b_offer_price"]) / product["b2b_price"] * 100, 2
                    )
                else:
                    product["discount_percentage"] = 0
            else:
                product["current_price"] = product["b2b_price"]
                product["discount_percentage"] = product["b2b_discount"] or 0
                
            product["original_price"] = product["b2b_price"]
        
        return product
    
    finally:
        cursor.close()
        conn.close()

# ============================ RATING & REVIEW ENDPOINTS ============================

class ReviewCreate(BaseModel):
    rating: float = Field(..., ge=1, le=5)  # Rating between 1 and 5
    comment: Optional[str] = None

@app.post("/products/{product_id}/review")
async def add_review(
    product_id: str,
    review: ReviewCreate,
    current_user_id: str = Depends(get_current_user)
):
    """
    Add a review/rating to a product.
    """
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    try:
        # Check if product exists
        cursor.execute("SELECT id FROM products WHERE id = %s", (product_id,))
        product = cursor.fetchone()
        
        if not product:
            raise HTTPException(status_code=404, detail="Product not found")
        
        # Check if user has already reviewed this product
        cursor.execute("""
            SELECT id FROM product_reviews 
            WHERE product_id = %s AND user_id = %s
        """, (product_id, current_user_id))
        
        if cursor.fetchone():
            raise HTTPException(status_code=400, detail="You have already reviewed this product")
        
        # Insert review
        review_id = str(uuid.uuid4())
        cursor.execute("""
            INSERT INTO product_reviews 
            (id, product_id, user_id, rating, comment, created_at)
            VALUES (%s, %s, %s, %s, %s, NOW())
        """, (review_id, product_id, current_user_id, review.rating, review.comment))
        
        # Calculate new average rating and review count
        cursor.execute("""
            SELECT 
                COUNT(*) as review_count,
                AVG(rating) as avg_rating
            FROM product_reviews 
            WHERE product_id = %s
        """, (product_id,))
        review_stats = cursor.fetchone()
        
        new_review_count = review_stats["review_count"] if review_stats else 0
        new_average_rating = round(review_stats["avg_rating"], 2) if review_stats and review_stats["avg_rating"] else 0
        
        # Note: Your products table doesn't have 'rating' and 'reviews' columns
        # If you want to store these in products table, you need to add them
        # For now, we'll just return the stats
        
        conn.commit()
        
        return {
            "message": "Review added successfully",
            "review_id": review_id,
            "new_rating": new_average_rating,
            "total_reviews": new_review_count
        }
    
    finally:
        cursor.close()
        conn.close()

@app.get("/products/{product_id}/reviews")
async def get_product_reviews(
    product_id: str,
    limit: int = 10,
    offset: int = 0
):
    """
    Get reviews for a specific product.
    """
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    try:
        # Check if product exists
        cursor.execute("SELECT id FROM products WHERE id = %s", (product_id,))
        if not cursor.fetchone():
            raise HTTPException(status_code=404, detail="Product not found")
        
        # Get reviews with user information
        query = """
            SELECT 
                pr.id, pr.rating, pr.comment, pr.created_at,
                au.email, au.full_name
            FROM product_reviews pr
            LEFT JOIN auth_users au ON pr.user_id = au.id
            WHERE pr.product_id = %s
            ORDER BY pr.created_at DESC
            LIMIT %s OFFSET %s
        """
        
        cursor.execute(query, (product_id, limit, offset))
        reviews = cursor.fetchall()
        
        # Get total count and average rating
        cursor.execute("""
            SELECT 
                COUNT(*) as total,
                AVG(rating) as avg_rating
            FROM product_reviews 
            WHERE product_id = %s
        """, (product_id,))
        stats = cursor.fetchone()
        
        return {
            "reviews": reviews,
            "total": stats["total"] if stats else 0,
            "average_rating": round(stats["avg_rating"], 2) if stats and stats["avg_rating"] else 0,
            "limit": limit,
            "offset": offset
        }
    
    finally:
        cursor.close()
        conn.close()

# Search products
@app.get("/products/search")
async def search_products(
    query: str,
    limit: int = 20,
    user_type: str = "b2c"
):
    """
    Search products by name or category.
    """
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    try:
        search_term = f"%{query}%"
        sql_query = """
            SELECT 
                id, name, category, description, status, stock, image,
                created_at, updated_at,
                b2c_price, b2b_price, 
                b2c_active_offer, b2b_active_offer,
                b2c_offer_price, b2b_offer_price,
                b2c_discount, b2b_discount,
                b2c_offer_start_date, b2c_offer_end_date,
                b2b_offer_start_date, b2b_offer_end_date,
                compare_at_price
            FROM products 
            WHERE status = 'Published' 
            AND (name LIKE %s OR category LIKE %s OR description LIKE %s)
            ORDER BY 
                CASE 
                    WHEN name LIKE %s THEN 1
                    WHEN category LIKE %s THEN 2
                    ELSE 3
                END,
                created_at DESC
            LIMIT %s
        """
        
        cursor.execute(sql_query, (search_term, search_term, search_term, search_term, search_term, limit))
        products = cursor.fetchall()
        
        # Get review counts and format prices
        current_time = datetime.now()
        for product in products:
            cursor.execute("""
                SELECT 
                    COUNT(*) as review_count,
                    AVG(rating) as avg_rating
                FROM product_reviews 
                WHERE product_id = %s
            """, (product["id"],))
            review_stats = cursor.fetchone()
            
            product["reviews"] = review_stats["review_count"] if review_stats else 0
            product["rating"] = round(review_stats["avg_rating"], 2) if review_stats and review_stats["avg_rating"] else 0
            
            if user_type == "b2c":
                # Check if offer is active
                is_offer_active = (
                    product["b2c_active_offer"] and 
                    product["b2c_offer_price"] > 0 and
                    (product["b2c_offer_start_date"] is None or product["b2c_offer_start_date"] <= current_time) and
                    (product["b2c_offer_end_date"] is None or product["b2c_offer_end_date"] >= current_time)
                )
                
                if is_offer_active:
                    product["current_price"] = product["b2c_offer_price"]
                else:
                    product["current_price"] = product["b2c_price"]
            else:  # b2b
                # Check if offer is active
                is_offer_active = (
                    product["b2b_active_offer"] and 
                    product["b2b_offer_price"] > 0 and
                    (product["b2b_offer_start_date"] is None or product["b2b_offer_start_date"] <= current_time) and
                    (product["b2b_offer_end_date"] is None or product["b2b_offer_end_date"] >= current_time)
                )
                
                if is_offer_active:
                    product["current_price"] = product["b2b_offer_price"]
                else:
                    product["current_price"] = product["b2b_price"]
        
        return {"query": query, "results": products}
    
    finally:
        cursor.close()
        conn.close()
# ============================ ORDER PLACEMENT ============================

@app.post("/orders/place")
async def place_order_from_app(order_data: OrderCreate, current_user_id: str = Depends(get_current_user)):
    """
    Receives a complete order object from the Flutter app and saves it to the MySQL 'orders' table.
    """
    conn = get_db_connection()
    cursor = conn.cursor()
    try:
        # 1. Prepare Order Items JSON
        # Since the SQL table has a single 'items' column, we need to serialize the list of products
        items_json_list = [item.model_dump_json() for item in order_data.products]
        items_json_string = json.dumps(items_json_list)

        # 2. Map to SQL table structure
        
        # Use the user_id as the 'customer' foreign key reference if available, or use email/name
        customer_name = order_data.customer_email.split('@')[0] # Simple default name

        # The 'type' field (varchar(50)) can be derived from the JWT user_type dependency.
        # We re-fetch user_type to ensure it's correct for the order record.
        try:
            from fastapi import Request
            request = Request.scope.get("request")
            token = request.headers.get("authorization").split(" ")[1]
            payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
            actual_user_type = payload.get("user_type", "b2c")
        except:
            actual_user_type = order_data.user_type # Fallback

        cursor.execute("""
            INSERT INTO orders (
                id, customer, email, amount, items_count, type, status, payment_status,  payment_method,date, address,items
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s,%s,%s)
        """, (
            order_data.order_id,
            current_user_id, # Use current_user_id (from auth_users.id) as the customer reference
            order_data.customer_email,
            order_data.total_price,
            len(order_data.products),
            actual_user_type,
            order_data.order_status,
            order_data.payment_status,
            order_data.payment_method,
            datetime.strptime(order_data.placed_on, '%d/%m/%Y').strftime('%Y-%m-%d %H:%M:%S'),
            order_data.customer_address_text
            ,items_json_string
        ))
        
        conn.commit()

        return {
            "message": "Order saved successfully",
            "order_id": order_data.order_id,
            "user_id_saved_as_customer": current_user_id,
            "payment_status": order_data.payment_status
        }
    except Exception as e:
        conn.rollback()
        print(f"Error saving order: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to save order: {str(e)}")
    finally:
        cursor.close()
        conn.close()
# In your FastAPI backend
@app.get("/orders/user/{user_email}")
async def get_orders_by_user(
    user_email: str,
    current_user_id: str = Depends(get_current_user)
):
    """
    Get all orders for a specific user by email.
    """
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    try:
        # Fetch orders for the user
        cursor.execute("""
            SELECT * FROM orders 
            WHERE email = %s 
            ORDER BY date DESC
        """, (user_email,))
        
        orders = cursor.fetchall()
        
        # Format the response to match your app's expected structure
        formatted_orders = []
        for order in orders:
            try:
                # Parse items JSON
                items = json.loads(order['items']) if order['items'] else []
            except:
                items = []
                
            formatted_orders.append({
                'id': order['id'],
                'customer': order['customer'],
                'email': order['email'],
                'amount': float(order['amount']) if order['amount'] else 0.0,
                'items_count': order['items_count'],
                'type': order['type'],
                'status': order['status'],
                'payment_status': order['payment_status'],
                'payment_method': order['payment_method'],
                'date': order['date'].strftime('%Y-%m-%d') if order['date'] else '',
                'address': order['address'],
                'items': items
            })
        
        return {
            "success": True,
            "orders": formatted_orders,
            "count": len(orders)
        }
        
    except Exception as e:
        print(f"Error fetching orders: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to fetch orders: {str(e)}")
    finally:
        cursor.close()
        conn.close()
# ============================ RETURN REQUESTS ============================
@app.post("/returns/create")
async def create_return_request(
    payload: ReturnCreate,
    current_user: str = Depends(get_current_user)
):
    conn = get_db_connection()
    cursor = conn.cursor()

    try:
        images_json = json.dumps(payload.images or [])
        cursor.execute(
            "SELECT email FROM auth_users WHERE id = %s",
            (current_user,)
        )
        user = cursor.fetchone()

        if not user:
            raise HTTPException(status_code=404, detail="User not found")

        email = user[0]

        # INSERT without specifying 'id' → auto-increment
        cursor.execute("""
            INSERT INTO returns (
                order_id,
                customer,
                email,
                reason,
                details,
                payment_method,
                refund_amount,
                images
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
        """, (
            payload.order_id,
            current_user,
            email,
            payload.reason,
            payload.details or "",
            payload.payment_method,
            payload.refund_amount,
            images_json
        ))

        # Get the auto-generated id
        cursor.execute("SELECT LAST_INSERT_ID()")
        new_return_id = cursor.fetchone()[0]

        conn.commit()

        return {
            "success": True,
            "message": "Return request created",
            "return_id": new_return_id  # now correct auto-incremented ID
        }

    except Exception as e:
        conn.rollback()
        print("RETURN CREATE ERROR:", e)
        raise HTTPException(status_code=500, detail=str(e))

    finally:
        cursor.close()
        conn.close()

@app.get("/returns/user")
async def get_user_returns(
    current_user=Depends(get_current_user)
):
    if not isinstance(current_user, dict):
        raise HTTPException(status_code=401, detail="Invalid user data")

    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    try:
        cursor.execute("""
            SELECT *
            FROM returns
            WHERE customer = %s
            ORDER BY created_at DESC
        """, (current_user))

        rows = cursor.fetchall()

        for r in rows:
            r["images"] = json.loads(r["images"] or "[]")
            r["created_at"] = r["created_at"].strftime('%Y-%m-%d')

        return {"success": True, "returns": rows}

    finally:
        cursor.close()
        conn.close()


@app.get("/returns/order/{order_id}")
async def get_returns_by_order(
    order_id: str,
   current_user: str = Depends(get_current_user) 
):
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)

    try:
        cursor.execute("""
            SELECT *
            FROM returns
            WHERE order_id = %s
              AND customer = %s
            ORDER BY created_at DESC
        """, (order_id, current_user))

        data = cursor.fetchall()

        for r in data:
            r["images"] = json.loads(r["images"] or "[]")
            r["created_at"] = r["created_at"].strftime('%Y-%m-%d')

        return {
            "success": True,
            "returns": data
        }

    except Exception as e:
        print("RETURN ORDER FETCH ERROR:", e)
        raise HTTPException(status_code=500, detail=str(e))

    finally:
        cursor.close()
        conn.close()


# ============================ RAZORPAY PAYMENT INTEGRATION ============================

@app.post("/payment/create-order")
async def create_razorpay_order(
    payment_data: CreatePaymentRequest,
    current_user_id: str = Depends(get_current_user)
):
    """
    Create a RazorPay order for payment
    """
    try:
        # Convert amount to paise (RazorPay expects amount in smallest currency unit)
        amount_in_paise = int(payment_data.amount * 100)
        
        # Create receipt if not provided
        receipt = payment_data.receipt or f"receipt_{datetime.now().strftime('%Y%m%d%H%M%S')}"
        
        # Create RazorPay order
        razorpay_order = razorpay_client.order.create({
            'amount': amount_in_paise,
            'currency': payment_data.currency,
            'receipt': receipt,
            'notes': payment_data.notes or {},
            'payment_capture': 1  # Auto-capture payment
        })
        
        return {
            "success": True,
            "order_id": razorpay_order['id'],
            "amount": razorpay_order['amount'],
            "currency": razorpay_order['currency'],
            "key": RAZORPAY_KEY_ID,
            "notes": razorpay_order.get('notes', {})
        }
        
    except Exception as e:
        print(f"Error creating RazorPay order: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to create payment order: {str(e)}")

@app.post("/payment/verify")
async def verify_payment(payload: VerifyPaymentRequest):
    try:
        # Step 1: Verify Razorpay signature
        generated_signature = hmac.new(
            RAZORPAY_KEY_SECRET.encode(),
            f"{payload.razorpay_order_id}|{payload.razorpay_payment_id}".encode(),
            hashlib.sha256
        ).hexdigest()

        if generated_signature != payload.razorpay_signature:
            raise HTTPException(status_code=400, detail="Invalid payment signature")
        payment = razorpay_client.payment.fetch(payload.razorpay_payment_id)
        actual_payment_method = payment.get("method")  # card, netbanking, upi, wallet
    

        # ✅ Step 2: Payment is verified
        # ❌ DO NOT CHECK DB HERE

        return {
            "success": True,
            "message": "Payment verified successfully",
            "order_id": payload.order_id,
            "razorpay_payment_id": payload.razorpay_payment_id,
            "payment_method": actual_payment_method
        }

    except HTTPException:
        raise
    except Exception as e:
        print("Error verifying payment:", e)
        raise HTTPException(status_code=500, detail="Payment verification failed")


@app.get("/payment/order-status/{order_id}")
async def get_payment_status(order_id: str):
    """
    Check payment status for an order
    """
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    try:
        cursor.execute("""
            SELECT id, payment_status,
                   amount, email, date
            FROM orders 
            WHERE id = %s
        """, (order_id,))
        
        order = cursor.fetchone()
        
        if not order:
            raise HTTPException(status_code=404, detail="Order not found")
        
        return {
            "success": True,
            "order_id": order['id'],
            "payment_status": order['payment_status'],
            "amount": float(order['amount']) if order['amount'] else 0.0,
            "email": order['email'],
            "date": order['date'].strftime('%Y-%m-%d %H:%M:%S') if order['date'] else None
        }
        
    except Exception as e:
        print(f"Error fetching payment status: {e}")
        raise HTTPException(status_code=500, detail=f"Failed to fetch payment status: {str(e)}")
    finally:
        cursor.close()
        conn.close()

@app.post("/payment/create-for-order/{order_id}")
async def create_payment_for_order(
    order_id: str,
    payload: CreatePaymentRequest
):
    try:
        amount_in_paise = int(payload.amount * 100)

        razorpay_order = razorpay_client.order.create({
            "amount": amount_in_paise,
            "currency": "INR",
            "receipt": f"receipt_{order_id}",
            "payment_capture": 1
        })

        return {
            "success": True,
            "razorpay_order_id": razorpay_order["id"],
            "amount": razorpay_order["amount"],
            "currency": razorpay_order["currency"],
            "key": RAZORPAY_KEY_ID
        }

    except Exception as e:
        print("Error creating Razorpay order:", e)
        raise HTTPException(status_code=500, detail="Payment creation failed")

