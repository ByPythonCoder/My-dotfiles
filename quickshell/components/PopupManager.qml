import QtQuick

QtObject {
    id: manager

    // Registries
    property var _major: ({})
    property var _modals: ({})
    property var _osds: ({})

    // State
    property string activeMajor: ""
    property string activeModal: ""
    property string activeOsd: ""
    property string pendingOsd: ""

    readonly property bool majorOpen: activeMajor !== ""
    readonly property bool modalOpen: activeModal !== ""

    // Registration
    function registerMajor(name, ref) {
        _major[name] = ref
    }

    function registerModal(name, ref) {
        _modals[name] = ref
    }

    function registerOsd(name, ref) {
        _osds[name] = ref
    }

    // Major popup lifecycle
    function openMajor(name) {
        if (modalOpen) return

        if (activeMajor === name) return

        if (activeMajor) {
            var cur = _major[activeMajor]
            if (cur) _closeRef(cur)
            activeMajor = ""
        }

        _closeAllOsds()
        pendingOsd = ""

        var ref = _major[name]
        if (ref) {
            _openRef(ref)
            activeMajor = name
        }
    }

    function toggleMajor(name) {
        if (activeMajor === name) {
            closeMajor(name)
        } else {
            openMajor(name)
        }
    }

    function closeMajor(name) {
        var ref = _major[name]
        if (!ref) return

        _closeRef(ref)
        if (activeMajor === name) {
            activeMajor = ""
            _flushPendingOsd()
        }
    }

    function closeCurrentMajor() {
        if (activeMajor) closeMajor(activeMajor)
    }

    // Modal lifecycle
    function openModal(name) {
        if (activeModal === name) return

        _closeAllMajor()
        _closeAllOsds()
        pendingOsd = ""

        var ref = _modals[name]
        if (ref) {
            _openModalRef(ref)
            activeModal = name
        }
    }

    function closeModal(name) {
        var ref = _modals[name]
        if (!ref) return

        _closeRef(ref)
        if (activeModal === name) {
            activeModal = ""
            _flushPendingOsd()
        }
    }

    // OSD lifecycle
    function showOsd(name) {
        if (majorOpen || modalOpen) {
            pendingOsd = name
            return
        }
        _showOsdNow(name)
    }

    function dismissOsd(name) {
        var ref = _osds[name]
        if (!ref) return

        _closeRef(ref)
        if (activeOsd === name) activeOsd = ""
    }

    function _showOsdNow(name) {
        if (activeOsd) {
            var cur = _osds[activeOsd]
            if (cur) _closeRef(cur)
        }

        var ref = _osds[name]
        if (ref) {
            _openRef(ref)
            activeOsd = name
        }
    }

    function _flushPendingOsd() {
        if (pendingOsd) {
            _showOsdNow(pendingOsd)
            pendingOsd = ""
        }
    }

    // Close all majors
    function _closeAllMajor() {
        for (var name in _major) {
            var ref = _major[name]
            if (ref) _closeRef(ref)
        }
        activeMajor = ""
    }

    function _closeAllOsds() {
        for (var name in _osds) {
            var ref = _osds[name]
            if (ref) _closeRef(ref)
        }
        activeOsd = ""
    }

    // Escape
    function handleEscape() {
        if (activeModal) {
            closeModal(activeModal)
            return
        }
        if (activeMajor) {
            closeCurrentMajor()
            return
        }
    }

    // Reflection-based open/close
    function _openRef(ref) {
        if (typeof ref.open === 'function')
            ref.open()
        else if (typeof ref.visibleState === 'boolean')
            ref.visibleState = true
        else if (typeof ref.osdVisible === 'boolean')
            ref.osdVisible = true
    }

    function _closeRef(ref) {
        if (typeof ref.close === 'function')
            ref.close()
        else if (typeof ref.visibleState === 'boolean')
            ref.visibleState = false
        else if (typeof ref.osdVisible === 'boolean')
            ref.osdVisible = false
    }

    function _openModalRef(ref) {
        if (typeof ref.openFor === 'function' && !ref.visibleState)
            ref.openFor(ref._pendingSsid || "", ref._pendingSecurity || "")
        else if (typeof ref.open === 'function' && !ref.visibleState)
            ref.open()
        else if (typeof ref.visibleState === 'boolean')
            ref.visibleState = true
    }
}
