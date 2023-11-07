package de.matthes.ndn_sensor_app

import android.os.Build
import androidx.annotation.RequiresApi
import androidx.lifecycle.lifecycleScope
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import net.named_data.jndn.Data
import net.named_data.jndn.Face
import net.named_data.jndn.Interest
import net.named_data.jndn.Name
import net.named_data.jndn.OnData
import net.named_data.jndn.OnTimeout
import java.io.IOException
import java.lang.IndexOutOfBoundsException
import java.net.ConnectException
import java.nio.ByteBuffer
import java.nio.channels.AsynchronousCloseException
import java.nio.charset.StandardCharsets


fun <R> CoroutineScope.executeAsyncTask(task: () -> R) = launch {
    val result = withContext(Dispatchers.IO) {
        // runs in background thread without blocking the Main Thread
        task()
    }
}


class NDNHandler : OnData, OnTimeout {
    var finished = false
    var data: Double? = null
    var timeout = false;

    @RequiresApi(Build.VERSION_CODES.N)
    override fun onData(interest: Interest?, data: Data) {
        val buffer = ByteBuffer.wrap(ByteArray(java.lang.Double.BYTES) { i -> data.content.buf()[i] }.reversedArray());
//        val receivedData = StandardCharsets.UTF_8.decode(data.content.buf()).toString()
        val receivedData = buffer.double;
//        println("Got data packet with names '${data.name.toUri()}'='$receivedData'")

        this.data = receivedData

        finished = true     // Must be last line to avoid race condition
    }

    override fun onTimeout(interest: Interest?) {
//        println("Timout for interest '${interest?.name?.toUri()}'")
        timeout = true;
        finished = true     // Must be last line to avoid race condition
    }

}


class MainActivity : FlutterActivity() {
    private val CHANNEL = "ndn.matthes.de/jndn"
    private var face = Face()


    private fun getData(call: MethodCall, result: MethodChannel.Result) {
        lifecycleScope.executeAsyncTask {
            val path = call.argument<String>("path")
            val name = Name(path);
            name.appendTimestamp(System.currentTimeMillis())
            name.append("data")

            val interest = Interest(name);
            interest.interestLifetimeMilliseconds = 3000.0;
            val ndnHandler = NDNHandler();

//            println("Express name: ${name.toUri()}")

            try {
                face.expressInterest(interest, ndnHandler, ndnHandler);

                while (!ndnHandler.finished) {
                    face.processEvents()
                    Thread.sleep(10)
                }

                if (ndnHandler.timeout) {
                    result.error("NDN_TIMEOUT", "No message received", null)
                } else {
                    result.success(ndnHandler.data)
                }

            } catch (e: AsynchronousCloseException) {
                result.error("NDN_ASYNC_CLOSE", "Async close error", null)
            } catch (e: ConnectException) {
                result.error("NDN_NFD_CONNECTION_ERROR", "Failed to connect to NDF", null)
            } catch (e: IOException) {
                // If you turn off the NDF app after it was working for some time, the existing face
                // instances crashes due to a broken pipe exception and must reconnect
                face = Face()
                println("Reconnecting face")
                result.error("NDN_NFD_CONNECTION_ERROR", "NDF connection reset", null)
            } catch (e: Exception) {
                result.error("NDN_UNKNOWN_EXCEPTION", "Unknown exception", e)
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getData" -> getData(call, result)
                else -> result.notImplemented();
            }
        }

        Interest.setDefaultCanBePrefix(true)
    }
}
