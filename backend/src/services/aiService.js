const Anthropic = require('@anthropic-ai/sdk');

const anthropic = new Anthropic({
  apiKey: process.env.CLAUDE_API_KEY,
});

const analyzeWithClaude = async (projectData) => {
  if (!process.env.CLAUDE_API_KEY || process.env.CLAUDE_API_KEY === 'your_key_here') {
    return {
      score: 70,
      summary: "Demo mode: Please configure CLAUDE_API_KEY for real analysis.",
      securityFindings: ["No API key provided"],
      qualityMetrics: { codeQuality: 5, documentation: 5 }
    };
  }

  const prompt = `Analyze this project submission:
    Title: ${projectData.title}
    Description: ${projectData.description}
    
    Provide a JSON response with:
    1. score (0-100)
    2. summary (string)
    3. securityFindings (array of strings)
    4. qualityMetrics (object with codeQuality and documentation as numbers 1-10)`;

  const msg = await anthropic.messages.create({
    model: "claude-3-sonnet-20240229",
    max_tokens: 1000,
    messages: [{ role: "user", content: prompt }],
  });

  try {
    return JSON.parse(msg.content[0].text);
  } catch (e) {
    return {
      score: 50,
      summary: "AI analysis completed but returned invalid format.",
      securityFindings: [],
      qualityMetrics: { codeQuality: 0, documentation: 0 }
    };
  }
};

module.exports = { analyzeWithClaude };