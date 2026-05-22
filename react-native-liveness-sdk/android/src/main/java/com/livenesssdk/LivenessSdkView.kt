package com.livenesssdk

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.graphics.RectF
import android.util.AttributeSet
import android.view.View
import android.widget.FrameLayout
import android.widget.TextView
import androidx.camera.core.*
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import com.facebook.react.bridge.Arguments
import com.facebook.react.bridge.ReactContext
import com.facebook.react.bridge.WritableMap
import com.facebook.react.uimanager.events.RCTEventEmitter
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.face.Face
import com.google.mlkit.vision.face.FaceDetection
import com.google.mlkit.vision.face.FaceDetectorOptions
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.io.File
import java.io.FileOutputStream

class LivenessSdkView(context: Context) : FrameLayout(context) {

  private var previewView: PreviewView = PreviewView(context)
  private var overlayView: LivenessOverlayView = LivenessOverlayView(context)
  private var instructionTextView: TextView = TextView(context)

  private var cameraExecutor: ExecutorService = Executors.newSingleThreadExecutor()
  private var faceDetector = FaceDetection.getClient(
    FaceDetectorOptions.Builder()
      .setPerformanceMode(FaceDetectorOptions.PERFORMANCE_MODE_FAST)
      .setLandmarkMode(FaceDetectorOptions.LANDMARK_MODE_ALL)
      .setClassificationMode(FaceDetectorOptions.CLASSIFICATION_MODE_ALL)
      .build()
  )

  private var embeddingGenerator: FaceEmbeddingGenerator = FaceEmbeddingGenerator(context)
  private var actions: List<String> = listOf()
  private var currentActionIndex = 0
  private var isCompleted = false
  private var lastResultBitmap: Bitmap? = null

  init {
    previewView.layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT)
    addView(previewView)

    overlayView.layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT)
    overlayView.setBackgroundColor(Color.TRANSPARENT)
    addView(overlayView)

    instructionTextView.layoutParams = LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT).apply {
      setMargins(0, 100, 0, 0)
    }
    instructionTextView.setTextColor(Color.WHITE)
    instructionTextView.textSize = 20f
    instructionTextView.textAlignment = TEXT_ALIGNMENT_CENTER
    addView(instructionTextView)

    startCamera()
  }

  private fun startCamera() {
    val cameraProviderFuture = ProcessCameraProvider.getInstance(context)
    cameraProviderFuture.addListener({
      val cameraProvider: ProcessCameraProvider = cameraProviderFuture.get()
      val preview = Preview.Builder().build().also {
        it.setSurfaceProvider(previewView.surfaceProvider)
      }

      val imageAnalyzer = ImageAnalysis.Builder()
        .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
        .build()
        .also {
          it.setAnalyzer(cameraExecutor) { imageProxy ->
            processImageProxy(imageProxy)
          }
        }

      val cameraSelector = CameraSelector.DEFAULT_FRONT_CAMERA

      try {
        val lifecycleOwner = (context as? ReactContext)?.currentActivity as? LifecycleOwner
        if (lifecycleOwner == null) return@addListener

        cameraProvider.unbindAll()
        cameraProvider.bindToLifecycle(
          lifecycleOwner,
          cameraSelector,
          preview,
          imageAnalyzer
        )
      } catch (exc: Exception) {
        // Handle exception
      }
    }, ContextCompat.getMainExecutor(context))
  }

  @androidx.annotation.OptIn(ExperimentalGetImage::class)
  private fun processImageProxy(imageProxy: ImageProxy) {
    val mediaImage = imageProxy.image
    if (mediaImage != null) {
      val image = InputImage.fromMediaImage(mediaImage, imageProxy.imageInfo.rotationDegrees)
      faceDetector.process(image)
        .addOnSuccessListener { faces ->
          if (faces.isNotEmpty()) {
            val face = faces[0]
            // Capture bitmap if we need it for embedding later (e.g. on last step)
            if (currentActionIndex == actions.size - 1) {
                lastResultBitmap = previewView.bitmap
            }
            checkLiveness(face)
          }
        }
        .addOnCompleteListener {
          imageProxy.close()
        }
    } else {
      imageProxy.close()
    }
  }

  private fun checkLiveness(face: Face) {
    if (isCompleted || actions.isEmpty()) return

    val currentAction = actions[currentActionIndex]
    var actionVerified = false

    when (currentAction) {
      "smile" -> if ((face.smilingProbability ?: 0f) > 0.7f) actionVerified = true
      "blink" -> if ((face.leftEyeOpenProbability ?: 1f) < 0.2f && (face.rightEyeOpenProbability ?: 1f) < 0.2f) actionVerified = true
      "turnLeft" -> if (face.headEulerAngleY > 20f) actionVerified = true
      "turnRight" -> if (face.headEulerAngleY < -20f) actionVerified = true
      "nodUp" -> if (face.headEulerAngleX > 15f) actionVerified = true
      "nodDown" -> if (face.headEulerAngleX < -15f) actionVerified = true
    }

    if (actionVerified) {
      if (currentActionIndex >= actions.size - 1) {
        isCompleted = true
        // Ensure we have the latest bitmap for the completion event
        val bitmap = previewView.bitmap ?: lastResultBitmap
        val imageUri = bitmap?.let { saveBitmap(it) }
        val embedding = bitmap?.let { embeddingGenerator.generateEmbedding(it) }
        emitEvent("completed", null, embedding, imageUri)
      } else {
        currentActionIndex++
        emitEvent("step_completed", actions[currentActionIndex])
      }
    }

    updateUI()
  }

  private fun updateUI() {
    post {
      if (isCompleted) {
        instructionTextView.text = "Liveness Check Completed!"
      } else if (actions.isNotEmpty()) {
        instructionTextView.text = "Please ${actions[currentActionIndex]}"
      }
    }
  }

  private fun saveBitmap(bitmap: Bitmap): String? {
    return try {
        val file = File(context.cacheDir, "liveness_${System.currentTimeMillis()}.jpg")
        val out = FileOutputStream(file)
        bitmap.compress(Bitmap.CompressFormat.JPEG, 90, out)
        out.flush()
        out.close()
        "file://${file.absolutePath}"
    } catch (e: Exception) {
        e.printStackTrace()
        null
    }
  }

  private fun emitEvent(status: String, currentStep: String?, embedding: FloatArray? = null, imageUri: String? = null) {
    val event = Arguments.createMap().apply {
      putString("status", status)
      currentStep?.let { putString("currentStep", it) }
      if (status == "completed") {
        val result = Arguments.createMap()
        result.putBoolean("success", true)
        imageUri?.let { result.putString("imageUri", it) }
        embedding?.let {
          val embeddingArray = Arguments.createArray()
          for (v in it) embeddingArray.pushDouble(v.toDouble())
          result.putArray("embedding", embeddingArray)
        }
        putMap("result", result)
      }
    }
    val reactContext = context as ReactContext
    reactContext.getJSModule(RCTEventEmitter::class.java).receiveEvent(id, "topLivenessEvent", event)
  }

  fun setActions(actions: List<String>) {
    this.actions = actions
    this.currentActionIndex = 0
    this.isCompleted = false
    updateUI()
  }

  fun setOvalColor(color: String) {
    overlayView.setOvalColor(Color.parseColor(color))
  }

  fun setInstructionTextColor(color: String) {
    instructionTextView.setTextColor(Color.parseColor(color))
  }

  fun setInstructionTextSize(size: Float) {
    instructionTextView.textSize = size
  }

  private inner class LivenessOverlayView(context: Context) : View(context) {
    private val paint = Paint().apply {
      style = Paint.Style.STROKE
      strokeWidth = 8f
      isAntiAlias = true
    }

    fun setOvalColor(color: Int) {
      paint.color = color
      invalidate()
    }

    override fun onDraw(canvas: Canvas) {
      super.onDraw(canvas)
      val width = width.toFloat()
      val height = height.toFloat()
      val ovalWidth = width * 0.7f
      val ovalHeight = height * 0.5f
      val left = (width - ovalWidth) / 2
      val top = (height - ovalHeight) / 2
      val rect = RectF(left, top, left + ovalWidth, top + ovalHeight)

      canvas.drawOval(rect, paint)
    }
  }
}
