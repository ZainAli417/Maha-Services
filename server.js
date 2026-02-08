const express = require('express');
const cors = require('cors');
const axios = require('axios');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json({ limit: '10mb' }));

// Groq API Configuration
const GROQ_API_URL = 'https://api.groq.com/openai/v1/chat/completions';
const GROQ_API_KEY = process.env.GROQ_API_KEY;
const MODEL = 'llama-3.3-70b-versatile'; // Most powerful Groq model

// Validate environment variables
if (!GROQ_API_KEY) {
  console.error('❌ FATAL ERROR: GROQ_API_KEY is not set in environment variables!');
  process.exit(1);
}

console.log('✅ Groq API Key found');
console.log(`🚀 Using model: ${MODEL}`);

// ============================================================
// AI MATCH ENDPOINT
// ============================================================
app.post('/ai-match', async (req, res) => {
  const startTime = Date.now();

  try {
    // ✅ STEP 1: Validate Request Body
    const { applicant, job } = req.body;

    if (!applicant || !job) {
      console.error('❌ VALIDATION ERROR: Missing applicant or job data');
      return res.status(400).json({
        error: 'Missing required fields',
        message: 'Both applicant and job data are required'
      });
    }


    // ✅ STEP 5: Send Response
    const duration = Date.now() - startTime;
    res.status(200).json(parsedResult);

  } catch (error) {
    const duration = Date.now() - startTime;

    res.status(500).json({
      error: 'Analysis failed',
      message: error.message,
      details: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });
  }
});

// ============================================================
// HELPER FUNCTIONS
// ============================================================

/**
 * Build the matching prompt for AI analysis
 */
function buildMatchingPrompt(applicant, job) {
  
  return `You are an expert HR system. Compare the candidate against the job.
Return a valid JSON object matching the requested structure.

JOB:
Title: ${job.title}
Required Experience: ${job.experience}
Key Skills: ${job.skills?.join(', ') || 'Not specified'}

CANDIDATE:
Name: ${applicant.name}
Experience: ${applicant.experienceYears} years
Recent Roles: ${applicant.workExperience}
Education: ${applicant.education}
Skills: ${applicant.skills?.join(', ') || 'Not specified'}

JSON Structure:
{
  "overallScore": number (0-100),
  "skillsMatch": number (0-100),
  "experienceMatch": number (0-100),
  "educationMatch": number (0-100),
  "strengths": ["string"],
  "weaknesses": ["string"],
  "recommendation": "string (Highly Recommended/Recommended/Consider/Not Recommended)",
  "detailedAnalysis": "string"
}

Important:
- All scores must be numbers between 0-100
- Provide at least 2-3 strengths and weaknesses
- Be objective and specific in your analysis
- Base recommendation on overall fit`;
}

/**
 * Call Groq API with the prompt
 */
async function callGroqAPI(prompt) {
  
  const requestBody = {
    model: MODEL,
    messages: [
      {
        role: "system",
        content: "You are a professional HR recruiter and talent analyst. Output only valid JSON with no additional text or markdown formatting."
      },
      {
        role: "user",
        content: prompt
      }
    ],
    response_format: { type: "json_object" }, // Force JSON output
    temperature: 0.1, // Low temperature for consistent results
    max_tokens: 2000,
  };


  try {
    const response = await axios.post(GROQ_API_URL, requestBody, {
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${GROQ_API_KEY}`,
      },
      timeout: 30000, // 30 second timeout
    });

    if (!response.data || !response.data.choices || !response.data.choices[0]) {
      throw new Error('Invalid response structure from Groq API');
    }

    const content = response.data.choices[0].message?.content;
    
    if (!content) {
      throw new Error('Empty content in Groq API response');
    }

 
    return content.trim();

  } catch (error) {
    console.error('❌ Groq API call failed');
    
    if (error.response) {
      // The request was made and the server responded with a status code
      // that falls out of the range of 2xx
      throw new Error(`Groq API error ${error.response.status}: ${JSON.stringify(error.response.data)}`);
    } else if (error.request) {
      // The request was made but no response was received
      console.error('No response received from Groq API');
      console.error('Request:', error.request);
      throw new Error('No response received from Groq API - network error or timeout');
    } else {
      // Something happened in setting up the request that triggered an Error
      console.error('Error setting up request:', error.message);
      throw new Error(`Request setup error: ${error.message}`);
    }
  }
}

/**
 * Parse Groq API response into structured result
 */
function parseGroqResponse(textResponse, applicant) {
  
  try {
    // Remove any potential markdown formatting
    let cleanedResponse = textResponse.trim();
    if (cleanedResponse.startsWith('```json')) {
      cleanedResponse = cleanedResponse.replace(/```json\n?/g, '').replace(/```\n?/g, '');
    }
    if (cleanedResponse.startsWith('```')) {
      cleanedResponse = cleanedResponse.replace(/```\n?/g, '');
    }


    const data = JSON.parse(cleanedResponse);

    // Validate and sanitize the data
    const result = {
      overallScore: safeInt(data.overallScore),
      skillsMatch: safeInt(data.skillsMatch),
      experienceMatch: safeInt(data.experienceMatch),
      educationMatch: safeInt(data.educationMatch),
      strengths: safeStringArray(data.strengths),
      weaknesses: safeStringArray(data.weaknesses),
      recommendation: data.recommendation?.toString() || 'Not Recommended',
      detailedAnalysis: data.detailedAnalysis?.toString() || 'No detailed analysis available',
    };

    return result;

  } catch (error) {
    console.error('❌ JSON parsing failed:', error.message);
    console.error('Failed to parse response:', textResponse);
    
    // Return error result
    return {
      overallScore: 0,
      skillsMatch: 0,
      experienceMatch: 0,
      educationMatch: 0,
      strengths: [],
      weaknesses: ['AI response parsing failed'],
      recommendation: 'Error',
      detailedAnalysis: `Failed to parse AI response: ${error.message}`,
    };
  }
}









app.post('/ai-jdbuild', async (req, res) => {
  const startTime = Date.now();
  console.log('\n╔═══════════════════════════════════════════════════╗');
  console.log('║         AI JD BUILDER REQUEST RECEIVED            ║');
  console.log('╚═══════════════════════════════════════════════════╝');
  console.log(`🕐 Timestamp: ${new Date().toISOString()}`);

  try {
    // ✅ STEP 1: Validate Request Body
    const { prompt, conversationHistory } = req.body;

    if (!prompt || typeof prompt !== 'string') {
      console.error('❌ VALIDATION ERROR: Invalid or missing prompt');
      return res.status(400).json({
        error: 'Invalid request',
        message: 'Prompt is required and must be a string'
      });
    }

    console.log('✅ STEP 1: Request validation passed');
    console.log('📝 User Prompt:', prompt);
    console.log('💬 Conversation History:', conversationHistory?.length || 0, 'messages');

    // ✅ STEP 2: Build Messages Array for Groq
    console.log('\n✅ STEP 2: Building conversation context...');
    
    const messages = [
      {
        role: "system",
        content: `You are an expert Airforce and Defense Sector Recruiter AI assistant specializing in creating professional Job Descriptions (JDs).

**Your Expertise:**
- Deep knowledge of Airforce and defense sector roles
- Understanding of security clearances, technical requirements, and operational needs
- Ability to write compelling, precise, and professional job descriptions

**Output Requirements:**
1. **Format**: Start with a concise 2-3 sentence introductory paragraph about the role
2. **Sections**: Use clear markdown formatting with ## for main sections
3. **Bullet Points**: Use • for all list items (responsibilities, qualifications, requirements)
4. **Tone**: Professional, authoritative, and engaging
5. **Structure**: 
   - Introduction paragraph
   - **Key Responsibilities** (bulleted)
   - **Required Qualifications** (bulleted)
   - **Preferred Qualifications** (bulleted, if applicable)
   - **Additional Information** (if relevant)

**Markdown Usage:**
- Use **bold** for emphasis on key terms and section titles
- Use bullet points (•) for lists
- Use ## for main section headers
- Keep formatting clean and professional

**Behavior:**
- Ask clarifying questions if the role description is vague
- Provide detailed, specific requirements based on industry standards
- Include relevant technical skills, experience levels, and certifications
- Tailor content to military/defense sector standards`
      }
    ];

    // Add conversation history if provided
    if (conversationHistory && Array.isArray(conversationHistory)) {
      conversationHistory.forEach(msg => {
        if (msg.role && msg.content) {
          messages.push({
            role: msg.role === 'user' ? 'user' : 'assistant',
            content: msg.content
          });
        }
      });
      console.log(`📚 Added ${conversationHistory.length} historical messages`);
    }

    // Add current user prompt
    messages.push({
      role: "user",
      content: prompt
    });

    console.log('✅ Built conversation with', messages.length, 'messages');

    // ✅ STEP 3: Call Groq API
    console.log('\n✅ STEP 3: Calling Groq API...');
    console.log(`🌐 API URL: ${GROQ_API_URL}`);
    console.log(`🤖 Model: ${MODEL}`);

    const requestBody = {
      model: MODEL,
      messages: messages,
      temperature: 0.7, // Higher for creative content
      max_tokens: 4000, // Allow longer responses for detailed JDs
      top_p: 0.9,
      stream: false
    };

    console.log('📤 Sending request to Groq...');

    const response = await axios.post(GROQ_API_URL, requestBody, {
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${GROQ_API_KEY}`,
      },
      timeout: 60000, // 60 second timeout for longer responses
    });

    console.log('📥 Groq API response status:', response.status);

    if (!response.data || !response.data.choices || !response.data.choices[0]) {
      throw new Error('Invalid response structure from Groq API');
    }

    const generatedText = response.data.choices[0].message?.content;

    if (!generatedText) {
      throw new Error('Empty content in Groq API response');
    }

    console.log('✅ STEP 3: Groq API call successful');
    console.log('📄 Generated text length:', generatedText.length, 'characters');
    console.log('📊 Token usage:', {
      prompt_tokens: response.data.usage?.prompt_tokens,
      completion_tokens: response.data.usage?.completion_tokens,
      total_tokens: response.data.usage?.total_tokens,
    });

    // ✅ STEP 4: Send Response
    const duration = Date.now() - startTime;
    console.log(`\n✅ STEP 4: Sending response to client`);
    console.log(`⏱️  Total processing time: ${duration}ms`);
    console.log('═══════════════════════════════════════════════════\n');

    res.status(200).json({
      text: generatedText,
      response: generatedText, // Include both for compatibility
      tokensUsed: response.data.usage?.total_tokens || 0,
      model: MODEL,
      processingTime: duration
    });

  } catch (error) {
    const duration = Date.now() - startTime;
    console.error('\n❌ ERROR OCCURRED IN JD BUILDER:');
    console.error('Error type:', error.name);
    console.error('Error message:', error.message);
    
    if (error.response) {
      console.error('Groq API Response Status:', error.response.status);
      console.error('Groq API Response Data:', error.response.data);
    }
    
    console.error('Error stack:', error.stack);
    console.error(`⏱️  Failed after: ${duration}ms`);
    console.error('═══════════════════════════════════════════════════\n');

    // Send error response
    res.status(500).json({
      error: 'JD generation failed',
      message: error.message,
      details: process.env.NODE_ENV === 'development' ? error.stack : undefined
    });
  }
});















/**
 * Safely convert value to integer (0-100)
 */
function safeInt(value) {
  if (value === null || value === undefined) return 0;
  
  let num;
  if (typeof value === 'number') {
    num = value;
  } else if (typeof value === 'string') {
    num = parseFloat(value);
  } else {
    return 0;
  }
  
  if (isNaN(num)) return 0;
  
  return Math.max(0, Math.min(100, Math.round(num)));
}






/**
 * Safely convert value to string array
 */
function safeStringArray(value) {
  if (!Array.isArray(value)) return [];
  return value.map(item => item?.toString() || '').filter(item => item.length > 0);
}

// ============================================================
// HEALTH CHECK ENDPOINT
// ============================================================
app.get('/health', (req, res) => {
  console.log('💓 Health check requested');
  res.status(200).json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    service: 'AI Match API',
    model: MODEL,
    groqApiConfigured: !!GROQ_API_KEY,
  });
});

// ============================================================
// ROOT ENDPOINT
// ============================================================
app.get('/', (req, res) => {
  res.status(200).json({
    message: 'AI Match API Server',
    version: '1.0.0',
    endpoints: {
      health: 'GET /health',
      aiMatch: 'POST /ai-match',
    },
    model: MODEL,
  });
});

// ============================================================
// ERROR HANDLING
// ============================================================
app.use((err, req, res, next) => {
  console.error('❌ Unhandled error:', err);
  res.status(500).json({
    error: 'Internal server error',
    message: err.message,
  });
});

// ============================================================
// START SERVER
// ============================================================
app.listen(PORT, () => {
  console.log('\n╔═══════════════════════════════════════════════════╗');
  console.log('║          AI MATCH API SERVER STARTED              ║');
  console.log('╚═══════════════════════════════════════════════════╝');
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`🌐 API URL: http://localhost:${PORT}`);
  console.log(`🤖 AI Model: ${MODEL}`);
  console.log(`✅ Groq API Key: ${GROQ_API_KEY ? 'Configured' : 'NOT CONFIGURED'}`);
  console.log('═══════════════════════════════════════════════════\n');
  console.log('📌 Available Endpoints:');
  console.log(`   GET  /            - API info`);
  console.log(`   GET  /health      - Health check`);
  console.log(`   POST /ai-match    - AI candidate matching`);
  console.log('\n🎯 Ready to process AI match requests!\n');
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('\n⚠️  SIGTERM signal received: closing HTTP server');
  server.close(() => {
    console.log('✅ HTTP server closed');
    process.exit(0);
  });
});