package site.shasmatic.flutter_veepoo_sdk

/** Which vendor SDK the plugin routes calls to. The Dart side picks it with `setBrand`. */
enum class WatchBrand {
    VEEPOO, YC;

    companion object {
        fun from(name: String?): WatchBrand? = values().firstOrNull { it.name.equals(name, ignoreCase = true) }
    }
}
