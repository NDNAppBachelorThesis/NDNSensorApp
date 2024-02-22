package de.matthes.ndn_sensor_app

import net.named_data.jndn.Data
import net.named_data.jndn.Interest
import net.named_data.jndn.OnData
import net.named_data.jndn.OnTimeout
import java.nio.ByteBuffer

/**
 * This is the most basic Interest handler. It can be extended to process received Data packets from
 * an NDN Interest packet
 */
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

    /**
     * Converts the received data to a ByteArray instance
     */
    protected fun dataToByteArray(data: Data, length: Int, offset: Int): ByteArray {
        if (data.content.buf() == null) {
            return ByteArray(0)
        }

        if (length + offset > data.content.size()) {
            throw RuntimeException("Requested data too large. Size=${data.content.size()}");
        }

        return ByteArray(length) { data.content.buf()[it + offset] }
    }

    /**
     * Converts a ByteArray to long
     */
    protected fun bytesToLong(byteArray: ByteArray): Long {
        return ByteBuffer.wrap(byteArray.reversedArray()).getLong()
    }

    /**
     * Converts a ByteArray to float
     */
    protected fun bytesToFloat(byteArray: ByteArray): Float {
        return ByteBuffer.wrap(byteArray.reversedArray()).getFloat()
    }

    /**
     * Converts a ByteArray to double
     */
    protected fun bytesToDouble(byteArray: ByteArray): Double {
        return ByteBuffer.wrap(byteArray.reversedArray()).getDouble()
    }

}

/**
 * A more advanced Interest handler, which also stores weather the request is finished or not
 */
abstract class BasicInterestHandler : InterestHandler() {
    private var finished = false

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

/**
 * The Interest handler for receiving sensor measurements
 */
class GetSensorDataHandler : BasicInterestHandler() {
    var data: Double? = null

    override fun onData(interest: Interest, data: Data) {
        this.data = bytesToDouble(dataToByteArray(data, 8, 0))
        setDone()
    }
}

/**
 * The Interest handler for receiving auto discovery data
 */
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

/**
 * The Interest handler for receiving the link qualities of a device
 */
class LinkQualityHandler : BasicInterestHandler() {
    val qualities: MutableMap<Long, Float> = mutableMapOf()

    override fun onData(interest: Interest, data: Data) {
        // Each entry is 12 bytes long. I can use this to determine the amount of entries in
        // the response
        for (i in 0..<data.content.size() / 12) {
            val id = bytesToLong(dataToByteArray(data, 8, 12 * i + 0))
            val quality = bytesToFloat(dataToByteArray(data, 4, 12 * i + 8));

            qualities[id] = quality
        }
        setDone()
    }

}
