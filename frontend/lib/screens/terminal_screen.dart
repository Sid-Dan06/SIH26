import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/pill.dart';
import '../widgets/primary_button.dart';
import '../services/api_service.dart';

class TerminalScreen extends StatefulWidget {
  const TerminalScreen({super.key});

  @override
  State<TerminalScreen> createState() => _TerminalScreenState();
}

class _TerminalScreenState extends State<TerminalScreen> {
  final TextEditingController _codeController = TextEditingController(
    text: "# Write Python code and tap Run\nprint('Hello, world!')",
  );

  bool isRunning = false;
  bool hasRun = false;
  bool lastRunSucceeded = false;
  String output = '';
  String error = '';

  Future<void> runCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty || isRunning) return;

    setState(() {
      isRunning = true;
    });

    try {
      final result = await ApiService.executeCode(code);
      setState(() {
        hasRun = true;
        lastRunSucceeded = result['success'] == true;
        output = (result['output'] ?? '').toString();
        error = (result['error'] ?? '').toString();
      });
    } catch (e) {
      setState(() {
        hasRun = true;
        lastRunSucceeded = false;
        output = '';
        error = 'Could not reach backend sandbox: $e';
      });
    } finally {
      if (mounted) setState(() => isRunning = false);
    }
  }

  void clearOutput() {
    setState(() {
      hasRun = false;
      output = '';
      error = '';
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppHeader(
            title: 'Terminal',
            subtitle: 'Run Python code directly in a sandboxed backend.',
            showLogo: false,
          ),
          const SizedBox(height: 18),
          const Row(
            children: [
              Pill(
                text: 'PYTHON 3',
                background: AppColors.lavender,
                foreground: AppColors.purple,
              ),
              SizedBox(width: 8),
              Pill(
                text: '5s TIME LIMIT',
                background: Color(0xFFFFF2CF),
                foreground: Color(0xFF8A6A00),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Code editor
          Container(
            decoration: BoxDecoration(
              color: AppColors.navy,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                  child: Row(
                    children: [
                      _dot(const Color(0xFFE95B67)),
                      const SizedBox(width: 5),
                      _dot(AppColors.yellow),
                      const SizedBox(width: 5),
                      _dot(AppColors.green),
                      const Spacer(),
                      const Text(
                        'main.py',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 9,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: TextField(
                    controller: _codeController,
                    maxLines: 10,
                    minLines: 6,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: Colors.white,
                      height: 1.5,
                    ),
                    cursorColor: AppColors.purple2,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      hintText: '# your code here',
                      hintStyle: TextStyle(color: Colors.white38),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                  text: isRunning ? 'Running...' : 'Run Code',
                  icon: Icons.play_arrow_rounded,
                  onPressed: isRunning ? null : runCode,
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: isRunning ? null : clearOutput,
                icon: const Icon(Icons.clear_rounded, size: 16, color: AppColors.purple),
                label: const Text(
                  'Clear',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.purple,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.purple, width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Text(
                'Output',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              const Spacer(),
              if (hasRun)
                Pill(
                  text: lastRunSucceeded ? 'SUCCESS' : 'ERROR',
                  background:
                      lastRunSucceeded ? AppColors.greenBg : const Color(0xFFFFE6E9),
                  foreground:
                      lastRunSucceeded ? AppColors.green : AppColors.red,
                ),
            ],
          ),
          const SizedBox(height: 9),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 120),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: !hasRun
                    ? AppColors.border
                    : (lastRunSucceeded ? AppColors.green : AppColors.red),
              ),
            ),
            child: isRunning
                ? const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.purple,
                      ),
                    ),
                  )
                : Text(
                    !hasRun
                        ? 'Run your code to see output here.'
                        : (error.isNotEmpty
                            ? error
                            : (output.isEmpty ? '(no output)' : output)),
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10.5,
                      height: 1.6,
                      color: !hasRun
                          ? AppColors.muted
                          : (error.isNotEmpty ? AppColors.red : AppColors.text),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color color) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}
