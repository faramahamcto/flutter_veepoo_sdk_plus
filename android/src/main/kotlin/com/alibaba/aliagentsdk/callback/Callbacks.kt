package com.alibaba.aliagentsdk.callback

// Callback stubs ycbtsdk links against - see AliAgentSdk.kt.

interface IBtDataUploadCallback { fun onDataUpload(data: ByteArray?) }

interface IConnectCallback {
    fun onIotDisconnected()
    fun onIotConnected()
    fun onIotConnectFailure(msg: String?, code: Int)
}

interface ID2Callback {
    fun onSuccess()
    fun onTimeOut()
    fun onError(msg: String?, code: Int)
}

interface IFgsStateCheckCallback {
    fun onFgsCheckSuccess()
    fun onFgsCheckError(msg: String?, code: Int)
}

interface IRegisterCallback {
    fun onRegisterSuccess(a: String?, b: String?, c: String?, d: String?, e: String?)
    fun onRegisterFailed(msg: String?, code: Int)
}

interface ISend2BtCallback {
    fun onSendSuccess()
    fun onSendFailed(msg: String?, code: Int)
}

interface ISend2LpCallback {
    fun onSendSuccess(code: Int)
    fun onSendFailed(a: Int, msg: String?, code: Int)
}
