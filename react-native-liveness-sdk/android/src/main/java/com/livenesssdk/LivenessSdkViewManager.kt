package com.livenesssdk

import android.graphics.Color
import com.facebook.react.bridge.ReadableArray
import com.facebook.react.module.annotations.ReactModule
import com.facebook.react.uimanager.SimpleViewManager
import com.facebook.react.uimanager.ThemedReactContext
import com.facebook.react.uimanager.ViewManagerDelegate
import com.facebook.react.uimanager.annotations.ReactProp
import com.facebook.react.viewmanagers.LivenessSdkViewManagerInterface
import com.facebook.react.viewmanagers.LivenessSdkViewManagerDelegate
import com.facebook.react.common.MapBuilder

@ReactModule(name = LivenessSdkViewManager.NAME)
class LivenessSdkViewManager : SimpleViewManager<LivenessSdkView>(),
  LivenessSdkViewManagerInterface<LivenessSdkView> {
  private val mDelegate: ViewManagerDelegate<LivenessSdkView>

  init {
    mDelegate = LivenessSdkViewManagerDelegate(this)
  }

  override fun getDelegate(): ViewManagerDelegate<LivenessSdkView>? {
    return mDelegate
  }

  override fun getName(): String {
    return NAME
  }

  public override fun createViewInstance(context: ThemedReactContext): LivenessSdkView {
    return LivenessSdkView(context)
  }

  @ReactProp(name = "actions")
  override fun setActions(view: LivenessSdkView?, value: ReadableArray?) {
    val actionsList = mutableListOf<String>()
    value?.let {
      for (i in 0 until it.size()) {
        actionsList.add(it.getString(i))
      }
    }
    view?.setActions(actionsList)
  }

  @ReactProp(name = "ovalColor")
  override fun setOvalColor(view: LivenessSdkView?, value: String?) {
    view?.setOvalColor(value ?: "#00FF00")
  }

  @ReactProp(name = "instructionTextColor")
  override fun setInstructionTextColor(view: LivenessSdkView?, value: String?) {
    view?.setInstructionTextColor(value ?: "#FFFFFF")
  }

  @ReactProp(name = "instructionTextSize")
  override fun setInstructionTextSize(view: LivenessSdkView?, value: Float) {
    view?.setInstructionTextSize(value)
  }

  override fun getExportedCustomDirectEventTypeConstants(): Map<String, Any>? {
    return MapBuilder.builder<String, Any>()
      .put("topLivenessEvent", MapBuilder.of("registrationName", "onLivenessEvent"))
      .build()
  }

  companion object {
    const val NAME = "LivenessSdkView"
  }
}
