import 'dart:convert';
import 'package:flutter/material.dart';

/// Widget para exibir avatar de usuário
/// Suporta URLs, base64 e fallback para iniciais
class UserAvatar extends StatelessWidget {
  final String? avatarData;
  final String userName;
  final double radius;
  final Color? backgroundColor;
  final TextStyle? textStyle;
  
  const UserAvatar({
    super.key,
    required this.avatarData,
    required this.userName,
    this.radius = 20,
    this.backgroundColor,
    this.textStyle,
  });
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bgColor = backgroundColor ?? colorScheme.primary;
    
    // Se não tem avatar, mostra iniciais
    if (avatarData == null || avatarData!.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        child: Text(
          _getInitials(userName),
          style: textStyle ?? TextStyle(
            fontSize: radius * 0.8,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    }
    
    // Verifica se é base64
    if (avatarData!.startsWith('data:image')) {
      try {
        // Remove o prefixo data:image/jpeg;base64, ou similar
        final base64String = avatarData!.split(',').last;
        final imageBytes = base64Decode(base64String);
        
        return CircleAvatar(
          radius: radius,
          backgroundColor: bgColor,
          backgroundImage: MemoryImage(imageBytes),
          onBackgroundImageError: (_, __) {
            // Se falhar ao carregar, volta para as iniciais
          },
          child: null,
        );
      } catch (e) {
        // Se falhar o decode, mostra iniciais
        return CircleAvatar(
          radius: radius,
          backgroundColor: bgColor,
          child: Text(
            _getInitials(userName),
            style: textStyle ?? TextStyle(
              fontSize: radius * 0.8,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        );
      }
    }
    
    // Se for URL
    if (avatarData!.startsWith('http')) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: bgColor,
        backgroundImage: NetworkImage(avatarData!),
        onBackgroundImageError: (_, __) {
          // Se falhar ao carregar, volta para as iniciais
        },
        child: null,
      );
    }
    
    // Fallback para iniciais
    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      child: Text(
        _getInitials(userName),
        style: textStyle ?? TextStyle(
          fontSize: radius * 0.8,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
  
  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      // Pega primeira letra do primeiro e último nome
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    
    // Se só tem um nome, pega as duas primeiras letras
    return name.length >= 2 
      ? name.substring(0, 2).toUpperCase() 
      : name[0].toUpperCase();
  }
}