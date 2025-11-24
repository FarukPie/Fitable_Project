import 'package:flutter/material.dart';
import '../core/constants.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData? icon;
  final bool isPassword;
  final TextInputType keyboardType;
  final bool isObscure;
  final VoidCallback? onEyePressed;
  final VoidCallback? onHelpPressed; // ✨ YENİ: Yardım butonuna basınca ne olacak?

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.icon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.isObscure = false,
    this.onEyePressed,
    this.onHelpPressed, // ✨ YENİ
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? isObscure : false,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: label,
        prefixIcon: icon != null ? Icon(icon, color: AppColors.primary) : null,
        
        // ✨ BURAYI GÜNCELLEDİK: Hem Şifre Gözü hem de Soru İşareti desteği
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(isObscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                onPressed: onEyePressed,
              )
            : (onHelpPressed != null // Eğer yardım fonksiyonu varsa Soru İşareti koy
                ? IconButton(
                    icon: const Icon(Icons.help_outline, color: Colors.orange),
                    onPressed: onHelpPressed,
                  )
                : null),
                
        filled: true,
        fillColor: AppColors.inputFill,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      ),
    );
  }
}