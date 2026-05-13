/**
 * @openapi
 * /api/chat/{conversationId}:
 *   get:
 *     summary: Retrieve message history
 *     tags: [Chat]
 *     security: [{ bearerAuth: [] }]
 *     parameters:
 *       - in: path
 *         name: conversationId
 *         required: true
 *         schema: { type: string }
 *     responses:
 *       200:
 *         description: List of messages
 */
router.get('/:conversationId', protect, async (req, res) => {
  const messages = await Message.find({ conversationId: req.params.conversationId });
  res.json(messages);
});