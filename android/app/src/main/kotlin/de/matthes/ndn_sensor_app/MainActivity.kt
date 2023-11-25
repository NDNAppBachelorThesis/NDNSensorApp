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
import net.named_data.jndn.encoding.Tlv0_3WireFormat
import net.named_data.jndn.encoding.WireFormat
import net.named_data.jndn.transport.TcpTransport
import net.named_data.jndn.transport.UdpTransport
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


class MainActivity : FlutterActivity() {
    private val CHANNEL = "ndn.matthes.de/jndn"
    private var face = Face(TcpTransport(), TcpTransport.ConnectionInfo("192.168.178.119", 6363))

    /**
     * Executes an NDN request.
     * Returns true if the request was successful
     */
    fun <T> executeNDNCall(
        handler: T,
        name: Name,
        result: MethodChannel.Result,
        timeout: Double = 3000.0,
        mustBeFresh: Boolean = true,
        onSuccess: (handler: T) -> Unit
    ) where T : InterestHandler {
        lifecycleScope.executeAsyncTask {
            val interest = Interest(name)
            interest.interestLifetimeMilliseconds = timeout
            interest.mustBeFresh = mustBeFresh

            try {
                face.expressInterest(interest, handler, handler);

                while (!handler.isDone()) {
                    face.processEvents()
                    Thread.sleep(10)
                }

                if (handler.hadTimeout()) {
                    result.error("NDN_TIMEOUT", "No message received", null)
                } else {
                    onSuccess(handler)
                }

            } catch (e: AsynchronousCloseException) {
                result.error("NDN_ASYNC_CLOSE", "Async close error", null)
            } catch (e: ConnectException) {
                result.error("NDN_NFD_CONNECTION_ERROR", "Failed to connect to NDF", null)
            } catch (e: IOException) {
                // If you turn off the NDF app after it was working for some time, the existing face
                // instances crashes due to a broken pipe exception and must reconnect
                face = Face(TcpTransport(), TcpTransport.ConnectionInfo("192.168.178.119", 6363))
                println("Reconnecting face")
                result.error("NDN_NFD_CONNECTION_ERROR", "NDF connection reset", null)
            } catch (e: Exception) {
                result.error("NDN_UNKNOWN_EXCEPTION", "Unknown exception", e)
            }
        }
    }

    private fun getData(call: MethodCall, result: MethodChannel.Result) {
        val handler = GetSensorDataHandler()
        val path = call.argument<String>("path")
        val name = Name(path)

        executeNDNCall(handler, name, result) {
            result.success(handler.data);
        }
    }

    private fun runDiscovery(call: MethodCall, result: MethodChannel.Result) {
        val handler = DiscoveryClientHandler()
        val visitedIds = call.argument<List<Long>>("visitedIds")
        val name = Name("/esp/discovery")
        visitedIds?.forEach {
            name.append(ByteBuffer.wrap(ByteArray(8)).putLong(it).array().reversedArray())
        }

        executeNDNCall(handler, name, result, timeout = 1000.0) {
            result.success(listOf( handler.responseId, handler.responsePaths));
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        WireFormat.setDefaultWireFormat(Tlv0_3WireFormat.get());
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getData" -> getData(call, result)
                "runDiscovery" -> runDiscovery(call, result)
                else -> result.notImplemented();
            }
        }

        Interest.setDefaultCanBePrefix(true)
    }
}
