import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../core/ai_store.dart';
import '../core/task_store.dart';
import '../main.dart'; // <-- For appSettings

class AIScreen extends StatefulWidget {
  const AIScreen({super.key});

  @override
  State<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends State<AIScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  final List<Map<String, dynamic>> _quickCommands = [
    {
      "label": "AUDIT",
      "prompt":
          "AUDIT: Provide a critical analysis of my progress. Am I moving the needle?",
      "icon": Icons.analytics_outlined
    },
    {
      "label": "STRATEGIZE",
      "prompt":
          "STRATEGY: Based on my pending tasks, what's the most efficient 90-minute deep work block?",
      "icon": Icons.architecture
    },
    {
      "label": "RESET",
      "prompt":
          "REFRESH: Give me a 5-minute mental reset protocol for high-stress focus.",
      "icon": Icons.psychology_outlined
    },
    {
      "label": "ROAST",
      "prompt":
          "ROAST: I'm procrastinating. Be brutal. End my excuses.",
      "icon": Icons.local_fire_department
    },
  ];

  void _handleAsk(String prompt) async {
    if (prompt.trim().isEmpty) return;

    setState(() => _isLoading = true);

    final taskData = TaskStore.tasks.isEmpty
        ? "No tasks logged yet."
        : TaskStore.tasks
            .map((t) =>
                "[${t.isCompleted ? 'COMPLETED' : 'OPEN'}] ${t.title}")
            .join("; ");

    final contextualPrompt =
        "LOG_DATA: {$taskData}. USER_REQUEST: $prompt";

    await AIStore.askGemini(contextualPrompt);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _controller.clear();
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isGhostMode = appSettings.ghostMode; // <-- replaced Hive
    final Color activeColor = Theme.of(context).primaryColor;
    final chatHistory = AIStore.history;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          isGhostMode ? "ANALYSIS_CORE" : "NEURAL_COMMAND",
          style: TextStyle(
            fontFamily: 'Monospace',
            fontSize: 14,
            letterSpacing: 4,
            color: activeColor,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.delete_sweep_outlined,
              color: Colors.white24,
              size: 20,
            ),
            onPressed: () =>
                setState(() => AIStore.clearChat()),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: chatHistory.isEmpty
                ? _buildEmptyState(activeColor)
                : _buildChatList(chatHistory, activeColor),
          ),
          if (_isLoading)
            _buildLoadingIndicator(activeColor),
          _buildQuickCommands(activeColor),
          _buildInputArea(activeColor),
        ],
      ),
    );
  }

  Widget _buildChatList(
      List<Content> history, Color activeColor) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 20),
      itemCount: history.length,
      itemBuilder: (context, index) {
        final message = history[index];
        if (message.role == 'system') {
          return const SizedBox.shrink();
        }

        final isUser = message.role == 'user';
        final text = message.parts
            .whereType<TextPart>()
            .map((e) => e.text)
            .join();

        final displayBody =
            isUser && text.contains("USER_REQUEST: ")
                ? text.split("USER_REQUEST: ").last
                : text;

        return ChatBubble(
          text: displayBody,
          isUser: isUser,
          activeColor: activeColor,
        );
      },
    );
  }

  Widget _buildLoadingIndicator(Color activeColor) {
    return Container(
      padding:
          const EdgeInsets.symmetric(vertical: 8),
      child: LinearProgressIndicator(
        color: activeColor,
        backgroundColor: Colors.white10,
        minHeight: 1,
      ),
    );
  }

  Widget _buildQuickCommands(Color activeColor) {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding:
            const EdgeInsets.symmetric(horizontal: 16),
        children: _quickCommands
            .map(
              (cmd) => Padding(
                padding:
                    const EdgeInsets.only(right: 8),
                child: ActionChip(
                  backgroundColor:
                      const Color(0xFF121212),
                  side: BorderSide(
                      color: activeColor
                          .withOpacity(0.3)),
                  label: Text(
                    cmd['label'],
                    style: TextStyle(
                        color: activeColor,
                        fontSize: 10,
                        fontWeight:
                            FontWeight.bold),
                  ),
                  onPressed: () =>
                      _handleAsk(cmd['prompt']),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildInputArea(Color activeColor) {
    return Container(
      padding:
          const EdgeInsets.fromLTRB(16, 0, 16, 30),
      child: TextField(
        controller: _controller,
        style: const TextStyle(
            color: Colors.white, fontSize: 14),
        cursorColor: activeColor,
        decoration: InputDecoration(
          hintText: "EXECUTE COMMAND...",
          hintStyle: const TextStyle(
              color: Colors.white24,
              fontSize: 12),
          filled: true,
          fillColor: const Color(0xFF0F0F0F),
          suffixIcon: IconButton(
            icon: Icon(Icons.send_rounded,
                color: activeColor),
            onPressed: () =>
                _handleAsk(_controller.text),
          ),
          enabledBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(4),
              borderSide:
                  const BorderSide(
                      color: Colors.white10)),
          focusedBorder: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(4),
              borderSide:
                  BorderSide(
                      color: activeColor)),
        ),
        onSubmitted: _handleAsk,
      ),
    );
  }

  Widget _buildEmptyState(Color activeColor) {
    return Center(
      child: Opacity(
        opacity: 0.3,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.memory,
                size: 40, color: activeColor),
            const SizedBox(height: 16),
            const Text(
              "NEURAL LINK STANDBY",
              style: TextStyle(
                  color: Colors.white,
                  letterSpacing: 5,
                  fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final Color activeColor;

  const ChatBubble({
    super.key,
    required this.text,
    required this.isUser,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Text(
            isUser
                ? "USER_INPUT"
                : "SYSTEM_OUTPUT",
            style: TextStyle(
                color: isUser
                    ? Colors.white38
                    : activeColor
                        .withOpacity(0.5),
                fontSize: 8,
                letterSpacing: 2,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Container(
            padding:
                const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUser
                  ? const Color(0xFF1A1A1A)
                  : Colors.transparent,
              border: isUser
                  ? null
                  : Border.all(
                      color: Colors.white10),
              borderRadius:
                  BorderRadius.circular(4),
            ),
            child: MarkdownBody(
              data: text,
              styleSheet:
                  MarkdownStyleSheet(
                p: TextStyle(
                    color: Colors.white
                        .withOpacity(0.9),
                    fontSize: 14,
                    height: 1.5,
                    fontFamily:
                        isUser ? null : 'Monospace'),
                strong: TextStyle(
                    color: activeColor),
                listBullet: TextStyle(
                    color: activeColor),
                code: const TextStyle(
                    backgroundColor:
                        Colors.white10,
                    color:
                        Colors.greenAccent,
                    fontFamily:
                        'Monospace'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
