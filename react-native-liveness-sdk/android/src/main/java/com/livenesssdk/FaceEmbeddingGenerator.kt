package com.livenesssdk

import android.content.Context
import android.graphics.Bitmap
import org.tensorflow.lite.Interpreter
import org.tensorflow.lite.support.common.ops.NormalizeOp
import org.tensorflow.lite.support.image.ImageProcessor
import org.tensorflow.lite.support.image.TensorImage
import org.tensorflow.lite.support.image.ops.ResizeOp
import java.nio.ByteBuffer
import java.nio.channels.FileChannel
import java.io.FileInputStream

class FaceEmbeddingGenerator(context: Context) {
    private var interpreter: Interpreter? = null

    init {
        try {
            val assetFileDescriptor = context.assets.openFd("mobile_facenet.tflite")
            val inputStream = FileInputStream(assetFileDescriptor.fileDescriptor)
            val fileChannel = inputStream.channel
            val startOffset = assetFileDescriptor.startOffset
            val declaredLength = assetFileDescriptor.declaredLength
            val modelBuffer = fileChannel.map(FileChannel.MapMode.READ_ONLY, startOffset, declaredLength)
            interpreter = Interpreter(modelBuffer)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    fun generateEmbedding(faceBitmap: Bitmap): FloatArray {
        if (interpreter == null) return floatArrayOf()

        val imageProcessor = ImageProcessor.Builder()
            .add(ResizeOp(112, 112, ResizeOp.Method.BILINEAR))
            .add(NormalizeOp(127.5f, 127.5f))
            .build()

        var tensorImage = TensorImage(org.tensorflow.lite.DataType.FLOAT32)
        tensorImage.load(faceBitmap)
        tensorImage = imageProcessor.process(tensorImage)

        val output = Array(1) { FloatArray(192) } // MobileFaceNet output is 192
        interpreter?.run(tensorImage.buffer, output)

        return output[0]
    }
}
