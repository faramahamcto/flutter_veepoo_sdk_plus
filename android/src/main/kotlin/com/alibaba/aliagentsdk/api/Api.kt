package com.alibaba.aliagentsdk.api

import com.alibaba.aliagentsdk.callback.IBtDataUploadCallback
import com.alibaba.aliagentsdk.callback.ID2Callback
import com.alibaba.aliagentsdk.callback.IConnectCallback
import com.alibaba.aliagentsdk.callback.IFgsStateCheckCallback
import com.alibaba.aliagentsdk.callback.IRegisterCallback
import com.alibaba.aliagentsdk.callback.ISend2BtCallback
import com.alibaba.aliagentsdk.callback.ISend2LpCallback

// API stubs ycbtsdk links against - see AliAgentSdk.kt.

interface IAliBt {
    fun setBtDataUploadCallback(callback: IBtDataUploadCallback?)
}

abstract class IJustDataTransportAliBt : IAliBt {
    abstract fun sendData(data: ByteArray?, callback: ISend2BtCallback?)
}

interface IAliAgent {
    fun customBtImpl(bt: IAliBt?)
    fun checkFgsState(callback: IFgsStateCheckCallback?)
    fun connectLp()
    fun disconnectLp()
    fun setLpConnectedCallback(callback: IConnectCallback?)
}

interface IAliAgentDev : IAliAgent {
    fun testSendData2Bt(a: String?, b: String?, callback: ISend2BtCallback?)
    fun testSendData2Bt(data: ByteArray?, callback: ISend2BtCallback?)
    fun testSendTransCodeToLp(a: String?, b: String?, callback: ISend2LpCallback?)
    fun testRegister(a: String?, b: String?, c: String?, d: String?, e: String?, callback: IRegisterCallback?)
    fun testRegister(a: String?, b: String?, c: String?, callback: IRegisterCallback?)
    fun testId2DataSend(a: String?, b: Long, callback: ID2Callback?)
}
