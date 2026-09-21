package br.com.gabiflow.gabiflow_mobile

import android.os.Bundle
import androidx.activity.enableEdgeToEdge
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Exibicao de ponta a ponta em todas as versoes do Android (o Android 15+
        // ja forca isso para apps com targetSdk 35+). Recomendacao do Play Console.
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
    }
}
