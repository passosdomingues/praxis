import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:praxis/services/app_provider.dart';
import 'package:praxis/ui/widgets/glass_container.dart';

class PlanDialog extends StatefulWidget {
  const PlanDialog({super.key});

  @override
  State<PlanDialog> createState() => _PlanDialogState();
}

class _PlanDialogState extends State<PlanDialog> {
  final TextEditingController _textController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  void _generate() async {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final plan = await provider.generatePlan();
    setState(() {
      _textController.text = plan;
      _isLoading = false;
    });
  }

  void _apply() async {
    setState(() => _isLoading = true);
    final provider = Provider.of<AppProvider>(context, listen: false);
    await provider.applyPlan(_textController.text);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
       backgroundColor: Colors.transparent,
       child: GlassContainer(
         width: 600,
         height: 500,
         child: Column(
           children: [
             Padding(
               padding: const EdgeInsets.all(16.0),
               child: Row(
                 children: [
                   const Icon(Icons.description, color: Colors.white),
                   const SizedBox(width: 8),
                   const Text("Implementation Plan", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                   const Spacer(),
                   IconButton(icon: const Icon(Icons.close, color: Colors.white70), onPressed: () => Navigator.pop(context)),
                 ],
               ),
             ),
             const Divider(color: Colors.white24, height: 1),
             Expanded(
               child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _textController,
                      maxLines: null,
                      expands: true,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 13, color: Colors.white),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Wait for generation or paste your plan here...",
                        hintStyle: TextStyle(color: Colors.white30),
                      ),
                    ),
                  ),
             ),
             const Divider(color: Colors.white24, height: 1),
             Padding(
               padding: const EdgeInsets.all(16.0),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.end,
                 children: [
                   TextButton(
                     onPressed: _generate, 
                     child: const Text("Regenerate from Board")
                   ),
                   const SizedBox(width: 8),
                   ElevatedButton.icon(
                     onPressed: _apply,
                     icon: const Icon(Icons.check),
                     label: const Text("Apply to Board"),
                     style: ElevatedButton.styleFrom(
                       backgroundColor: Theme.of(context).primaryColor,
                       foregroundColor: Colors.white,
                     ),
                   )
                 ],
               ),
             )
           ],
         ),
       ),
    );
  }
}
