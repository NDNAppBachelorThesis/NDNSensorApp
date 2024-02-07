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

    protected fun getDataAsDouble(data: Data): Double {
        return ByteBuffer.wrap(getDataAsByteArray(data).reversedArray()).double;
    }

    protected fun getDataAsFloat(data: Data): Float {
        return ByteBuffer.wrap(getDataAsByteArray(data).reversedArray()).getFloat();
    }

    /**
     * Converts the data to a ByteArray
     */
    protected fun getDataAsByteArray(data: Data): ByteArray {
        if (data.content.buf() == null) {
            return ByteArray(0)
        }

        return ByteArray(data.content.size()) { i -> data.content.buf()[i] }
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
        this.data = getDataAsDouble(data)
        setDone()
    }
}

class DiscoveryClientHandler : BasicInterestHandler() {
    var responseId: Long? = null
    var responsePaths = mutableListOf<String>()

    override fun onData(interest: Interest, data: Data) {
        println("Got data packet with name ${data.name.toUri()}")
        val paths = String(getDataAsByteArray(data))
            .split('\u0000')
            .filter { it.isNotEmpty() }    // Separated by 0-Byte
        println("Paths: ${paths}")

        responseId = data.name[-1].toEscapedString().toLongOrNull()
        responsePaths.addAll(paths)

        setDone()
    }
}

class LinkQualityHandler : BasicInterestHandler() {
    var linkQuality: Float? = null

    override fun onData(interest: Interest, data: Data) {
        this.linkQuality = getDataAsFloat(data)
        setDone()
    }
}