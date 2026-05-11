const { GoogleGenerativeAI } = require("@google/generative-ai");

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

const analyzeWithGemini = async (projectData) => {
  if (!process.env.GEMINI_API_KEY || process.env.GEMINI_API_KEY === 'your_key_here') {
    return {
      score: 50,
      summary: "Demo mode: GEMINI_API_KEY not found.",
      securityFindings: ["No analysis performed"],
      qualityMetrics: { codeQuality: 0, documentation: 0 }
    };
  }

  const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });

  const prompt = `Analyze this project and return ONLY a valid JSON object.
    Title: ${projectData.title}
    Description: ${projectData.description}
    
    JSON Format:
    {
      "score": number (0-100),
      "summary": "string",
      "securityFindings": ["string"],
      "qualityMetrics": { "codeQuality": number (1-10), "documentation": number (1-10) }
    }`;

  const result = await model.generateContent(prompt);
  const response = await result.response;
  const text = response.text();
  
  try {
    // Clean potential markdown code blocks from AI response
    const cleanedText = text.replace(/```json/g, "").replace(/```/g, "").trim();
    return JSON.parse(cleanedText);
  } catch (e) {
    console.error("AI Parsing Error:", text);
    return {
      score: 0,
      summary: "AI response format error.",
      securityFindings: [],
      qualityMetrics: { codeQuality: 0, documentation: 0 }
    };
  }
};

module.exports = { analyzeWithClaude: analyzeWithGemini }; 
