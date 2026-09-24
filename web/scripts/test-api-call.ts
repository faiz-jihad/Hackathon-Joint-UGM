process.env.JWT_SECRET = "retiva-healthcare-jwt-secret-replace-in-production-min-32-chars";
import { JwtTokenService } from '../infrastructure/security/jwt-token.service';



async function testApi() {
  const token = new JwtTokenService().generateToken({
    userId: 'usr-001',
    email: 'dr.hendra@retina.id',
    role: 'OPHTHALMOLOGIST'
  });

  console.log('Generated token length:', token.length);

  try {
    const res = await fetch('http://localhost:3001/api/v1/patients', {
      headers: { Authorization: `Bearer ${token}` }
    });
    const text = await res.text();
    console.log('STATUS:', res.status);
    const match = text.match(/<script id="__NEXT_DATA__" type="application\/json">([^<]+)<\/script>/);
    if (match) {
      console.log('NEXT_DATA:', JSON.stringify(JSON.parse(match[1]), null, 2));
    } else {
      console.log('RESPONSE:', text.slice(0, 1000));
    }



  } catch (err: any) {
    console.error('ERROR:', err.message);
  }
}

testApi();
