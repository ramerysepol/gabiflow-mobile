# Regras R8/ProGuard para o release do GabiFlow.
# Objetivo: ofuscar/encolher o codigo Android sem quebrar Flutter e plugins que
# usam reflection/JNI. Mantemos o minimo necessario e silenciamos avisos de
# classes opcionais (ex.: Play Core, que o engine referencia mas nem sempre existe).

# ---- Flutter engine/embedding ----
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.**

# ---- Play Core (deferred components / split install referenciados pelo engine) ----
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# ---- Firebase / Google ----
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# ---- Anotacoes, assinaturas genericas, exceptions e enums ----
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod, Exceptions
-keepclassmembers enum * { *; }

# ---- Modelos (de)serializados: preserva nomes de campos ----
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# ---- Kotlin metadata / coroutines (usadas por varios plugins) ----
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-dontwarn kotlinx.**

# ---- Componentes nativos comuns em plugins (audio/midia, notificacoes) ----
# just_audio / ExoPlayer (media3)
-dontwarn androidx.media3.**
-keep class androidx.media3.** { *; }

# local_auth / biometria (AndroidX)
-keep class androidx.biometric.** { *; }
-dontwarn androidx.biometric.**

# Evita remover construtores usados via reflection por libs de JSON/serializacao.
-keepclassmembers class * {
    public <init>(...);
}

# ---- Classes opcionais ausentes (gerado pelo R8) ----
# Apache Tika (deteccao de tipo de arquivo, puxado por plugin) referencia APIs
# de XML (StAX) que nao existem no Android. Sao caminhos nao usados em runtime.
-dontwarn javax.xml.stream.**
-dontwarn org.apache.tika.**
