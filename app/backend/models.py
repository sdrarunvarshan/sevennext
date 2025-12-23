from pydantic import BaseModel, EmailStr ,Field
from typing import Optional , List

class Token(BaseModel):
    access_token: str
    token_type: str

class UserCreate(BaseModel):
    email: EmailStr
    password: str
    full_name: Optional[str] = None
    phone_number: Optional[str] = None
    business_name: Optional[str] = None

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class PhoneRequest(BaseModel):
    phone: str

def normalize_phone(phone: str) -> str:
    phone = phone.strip().replace(" ", "")
    if phone.startswith("+"):
        return phone
    if phone.startswith("91") and len(phone) == 12:
        return f"+{phone}"
    if len(phone) == 10:
        return f"+91{phone}"
    raise HTTPException(status_code=400, detail="Invalid phone number format")

class VerifyOtpRequest(BaseModel):
    phone: str
    otp: str  
    type: Optional[str] = None  # Add this field  

class ResetPasswordRequest(BaseModel):
    email: EmailStr
    phone: str
    otp: str
    new_password: str
        
class AddressCreate(BaseModel):
    street: str
    city: str
    postal_code: Optional[int] = None
    state: Optional[str] = None
    country: str
    name: str = "Home"
    is_default: bool = False

class B2BApplicationCreate(BaseModel):
    business_name: str
    gstin: str
    pan: str
    phone_number: str
    gst_certificate_url: str
    business_license_url: str
    address_id: str


class AddressPayload(BaseModel):
    street: str
    city: str
    postal_code: Optional[int] = None
    state: Optional[str] = None
    country: Optional[str] = ""
    name: Optional[str] = "Home"
    is_default: Optional[bool] = False


class B2CRegister(BaseModel):
    email: EmailStr
    password: str
    full_name: Optional[str] = None
    phone_number: Optional[str] = None
    raw_user_meta_data: Optional[dict] = None
    address: Optional[AddressPayload] = None
class OrderedProductBase(BaseModel):
    name: str
    imageUrl: str
    quantity: int
    colorHex: str

class OrderCreate(BaseModel):
    order_id: str # Unique ID from Flutter (e.g., timestamp)
    placed_on: str # Date string
    order_status: str # e.g., 'processing'
    processing_status: str
    packed_status: str
    shipped_status: str
    delivered_status: str
    products: List[OrderedProductBase]
    total_price: float
    shipping_fee: float
    customer_email: str
    customer_address_text: str
    user_type: str = "b2c" 
    payment_status: str
    payment_method: str
    

class ReturnCreate(BaseModel):
    order_id: str
    reason: str
    details: Optional[str] = ""
    payment_method: Optional[str] = None
    refund_amount: float
    images: List[str] = Field(default_factory=list)

class CreatePaymentRequest(BaseModel):
    amount: float
    currency: str = "INR"
    receipt: str = None
    notes: dict = None

class VerifyPaymentRequest(BaseModel):
    razorpay_order_id: str
    razorpay_payment_id: str
    razorpay_signature: str
    order_id: str  # Your internal order ID    