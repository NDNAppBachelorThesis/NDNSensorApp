package de.matthes.ndn_sensor_app

import net.named_data.jndn.Data
import net.named_data.jndn.Interest
import net.named_data.jndn.OnData
import net.named_data.jndn.OnTimeout
import java.nio.ByteBuffer

abstract class InterestHandler : OnData, OnTimeout {
    private var hadTimeout = false
    abstract fun setDone()
    abstract fun isDone(): Boolean
    abstract fun abort()

    fun hadTimeout(): Boolean {
        return hadTimeout
    }

    override fun onTimeout(interest: Interest?) {
        println("Timeout for interest ${interest?.name?.toUri()}")
        hadTimeout = true
        abort();
    }

    protected fun dataToByteArray(data: Data, length: Int, offset: Int): ByteArray {
        if (data.content.buf() == null) {
            return ByteArray(0)
        }

        if (length + offset > data.content.size()) {
            throw RuntimeException("Requested data too large. Size=${data.content.size()}");
        }

        return ByteArray(length) { data.content.buf()[it + offset] }
    }

    protected fun bytesToLong(byteArray: ByteArray): Long {
        return ByteBuffer.wrap(byteArray.reversedArray()).getLong()
    }

    protected fun bytesToFloat(byteArray: ByteArray): Float {
        return ByteBuffer.wrap(byteArray.reversedArray()).getFloat()
    }

    protected fun bytesToDouble(byteArray: ByteArray): Double {
        return ByteBuffer.wrap(byteArray.reversedArray()).getDouble()
    }

}

abstract class BasicInterestHandler : InterestHandler() {
    protected var finished = false

    override fun setDone() {
        finished = true
    }

    override fun isDone(): Boolean {
        return finished
    }

    override fun abort() {
        finished = true;
    }
}

class GetSensorDataHandler : BasicInterestHandler() {
    var data: Double? = null

    override fun onData(interest: Interest, data: Data) {
        this.data = bytesToDouble(dataToByteArray(data, 8, 0))
        setDone()
    }
}

class DiscoveryClientHandler : BasicInterestHandler() {
    var responseId: Long? = null
    var responsePaths = mutableListOf<String>()
    var isNFD = false

    override fun onData(interest: Interest, data: Data) {
        println("Got data packet with name ${data.name.toUri()}")

        if (data.name.size() >= 4 && data.name[-1].toEscapedString() == "1") {
            println(" -> Is NFD");
            isNFD = true
        } else {
            val paths = String(dataToByteArray(data, data.content.size(), 0))
                .split('\u0000')
                .filter { it.isNotEmpty() }    // Separated by 0-Byte
            println("Paths: $paths")
            responsePaths.addAll(paths)
        }

        responseId = data.name[-2].toEscapedString().toLongOrNull()

        setDone()
    }
}

class LinkQualityHandler : BasicInterestHandler() {
    val qualities: MutableMap<Long, Float> = mutableMapOf()

    override fun onData(interest: Interest, data: Data) {
        for (i in 0..<data.content.size() / 12) {
            val id = bytesToLong(dataToByteArray(data, 8, 12 * i + 0))
            val quality = bytesToFloat(dataToByteArray(data, 4, 12 * i + 8));

            qualities[id] = quality
        }
        setDone()
    }

}
