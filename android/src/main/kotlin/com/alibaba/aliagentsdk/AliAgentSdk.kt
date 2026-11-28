package com.alibaba.aliagentsdk

import android.content.Context
import com.alibaba.aliagentsdk.api.IAliAgentDev
import com.alibaba.aliagentsdk.api.IAliBt
import com.alibaba.aliagentsdk.callback.ID2Callback
import com.alibaba.aliagentsdk.callback.IConnectCallback
import com.alibaba.aliagentsdk.callback.IFgsStateCheckCallback
import com.alibaba.aliagentsdk.callback.IRegisterCallback
import com.alibaba.aliagentsdk.callback.ISend2BtCallback
import com.alibaba.aliagentsdk.callback.ISend2LpCallback

/**
 * No-op stand-in for the vendor's Alibaba IoT agent (AliAgent-release-*.aar), which we don't bundle.
 *
 * ycbtsdk's Jieli WatchManager calls `ALiIOTKit.getInstance(ctx).destroy()` on every disconnect of a
 * Jieli-chip YC watch; without these classes that throws NoClassDefFoundError on a binder thread and
 * kills the app. The real agent would pull in MQTT/fastjson and connect to Alibaba's cloud - a feature
 * we don't use - so these stubs only satisfy the API ycbtsdk links against (same signatures).
 */
class AliAgentSdk private constructor() {
    fun init(context: Context, debug: Boolean) {}
    fun getAgent(): com.alibaba.aliagentsdk.api.IAliAgent = NoOpAgent

    companion object {
        private val instance = AliAgentSdk()
        @JvmStatic fun getInstance(): AliAgentSdk = instance
    }
}

private object NoOpAgent : IAliAgentDev {
    override fun customBtImpl(bt: IAliBt?) {}
    override fun checkFgsState(callback: IFgsStateCheckCallback?) {}
    override fun connectLp() {}
    override fun disconnectLp() {}
    override fun setLpConnectedCallback(callback: IConnectCallback?) {}
    override fun testSendData2Bt(a: String?, b: String?, callback: ISend2BtCallback?) {}
    override fun testSendData2Bt(data: ByteArray?, callback: ISend2BtCallback?) {}
    override fun testSendTransCodeToLp(a: String?, b: String?, callback: ISend2LpCallback?) {}
    override fun testRegister(a: String?, b: String?, c: String?, d: String?, e: String?, callback: IRegisterCallback?) {}
    override fun testRegister(a: String?, b: String?, c: String?, callback: IRegisterCallback?) {}
    override fun testId2DataSend(a: String?, b: Long, callback: ID2Callback?) {}
}
