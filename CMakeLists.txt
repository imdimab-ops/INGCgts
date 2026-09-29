cmake_minimum_required(VERSION 3.16)

project(INGCgts VERSION 1.2 LANGUAGES CXX)

# Добавляем версию проекта и номер сборки
set(SOURCE_NUMBER_FILE "${CMAKE_SOURCE_DIR}/version/build_number.txt")
if(EXISTS ${SOURCE_NUMBER_FILE})
    file(READ ${SOURCE_NUMBER_FILE} BUILD_NUMBER)
    math(EXPR BUILD_NUMBER "${BUILD_NUMBER} + 1")
else()
    set(BUILD_NUMBER 1)
endif()
file(WRITE ${SOURCE_NUMBER_FILE} "${BUILD_NUMBER}")

# Установка версии проекта
set(PROJECT_VERSION "${PROJECT_VERSION}")
set(PROJECT_VERSION_BUILD "${PROJECT_VERSION}.${BUILD_NUMBER}")
set(PROJECT_VERSION_FULL "${PROJECT_NAME}.${PROJECT_VERSION}.${BUILD_NUMBER}")
# Создаем конфигурационный файл версии
configure_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/version/version.in.h
    ${CMAKE_CURRENT_SOURCE_DIR}/version/version.h
)

# Настраиваем манифест (читаем шаблон и перезаписываем AndroidManifest.xml)
# Через стандратную настройку прописывания версии в манифесте а авто режиме не получилось
# Qt подхватывает манифест из папки с исходниками и подставляет дефолные значения:
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/android/AndroidManifest.in.xml")
    # Читаем манифест
    file(READ "${CMAKE_CURRENT_SOURCE_DIR}/android/AndroidManifest.in.xml" MANIFEST_CONTENT)

    # Заменяем шаблоны
    string(REPLACE "-- %%INSERT_VERSION_NAME%% --" "${PROJECT_VERSION}" MANIFEST_CONTENT "${MANIFEST_CONTENT}")
    string(REPLACE "-- %%INSERT_VERSION_CODE%% --" "${BUILD_NUMBER}" MANIFEST_CONTENT "${MANIFEST_CONTENT}")

    # Сохраняем новый манифест в папке с исходниками
    file(WRITE "${CMAKE_CURRENT_SOURCE_DIR}/android/AndroidManifest.xml" "${MANIFEST_CONTENT}")

    message(STATUS "Version Code: ${BUILD_NUMBER}")
    message(STATUS "Version Name: ${PROJECT_VERSION}")
else()
    message(FATAL_ERROR "AndroidManifest.xml not found!")
endif()

set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_STANDARD 17)

find_package(Qt6 REQUIRED COMPONENTS Quick)
qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(appINGCgts
    main.cpp
    appengine.h             appengine.cpp
    version/version.h
    tcpclient/tcpthread.h   tcpclient/tcpthread.cpp
    tcpclient/tcpclient.h   tcpclient/tcpclient.cpp
    tcpclient/processdata.h tcpclient/processdata.cpp
    tcpclient/parsingdata.h tcpclient/parsingdata.cpp
    lib/qcustomplot.h       lib/qcustomplot.cpp
    lib/customplotitem.h    lib/customplotitem.cpp
    lib/millisecondticker.h
    insetshelper.h          insetshelper.cpp
    applib.h                applib.cpp
)

qt_add_qml_module(appINGCgts
    URI INGCgts
    VERSION 2.0
    QML_FILES
        qml/Main.qml
        qml/SplashScreen.qml
        qml/ConnDialog.qml
        qml/About.qml
        qml/Home.qml
        qml/GTU.qml
        qml/Chart.qml
        qml/MessageLog.qml
        qml/SystemLog.qml
        # qml/Home_test.qml
        qml/components/AIapp.qml
        qml/components/AIpb.qml
        qml/components/MultiTouch.qml
        qml/components/MultiTouchRect.qml
        qml/components/MessageBar.qml
        qml/components/MessagePopup.qml

    SOURCES
        android/AndroidManifest.in.xml
        android/AndroidManifest.xml
        android/build.gradle
        android/res/values/libs.xml
        android/res/xml/qtprovider_paths.xml
)

# Добавляем ресурсы (если используете .qrc)
qt_add_resources(appINGCgts Resources
    PREFIX "/"
    FILES
    "img/logo_fast.gif"
    "img/logo_slow.gif"
    "img/icon/menu.svg"
    "img/icon/settings.svg"
    "img/icon/home.svg"
    "img/icon/turbine.svg"
    "img/icon/chart.svg"
    "img/icon/messagelog.svg"
    "img/icon/plugconnected.svg"
    "img/icon/plugdisconnected.svg"
    "img/icon/success.svg"
    "img/icon/successErr.svg"
    "img/home/block.png"
    "img/home/smoke.gif"
    "img/gtu/base.svg"
    "img/gtu/cam1.svg"
    "img/gtu/cam2.svg"
    "img/gtu/cam3.svg"
    "img/gtu/cam4.svg"
    "img/gtu/fire.gif"
    "img/gtu/firecam.gif"
    "img/gtu/rotate.gif"
    "img/gtu/turboFireEx.svg"
    "img/qmlcomponents/rotate_right.svg"
    "img/qmlcomponents/chartOn.svg"
    "img/qmlcomponents/chartOff.svg"
    # другие файлы, если нужны
)

# Включаем отладку Qml
target_compile_definitions(appINGCgts PRIVATE QT_QML_DEBUG)
target_link_libraries(appINGCgts PRIVATE Qt6::Quick)

# Установка HighDPI атрибутов
target_compile_definitions(appINGCgts PRIVATE QT_ENABLE_HIGHDPI_SCALING=1)

find_package(Qt6 REQUIRED COMPONENTS Network)
target_link_libraries(appINGCgts PRIVATE Qt6::Network)

# Для QOperatingSystemVersion
find_package(Qt6 REQUIRED COMPONENTS Core)
target_link_libraries(appINGCgts PRIVATE Qt6::Core)

# Для работы QCustomPlot
find_package(Qt6 REQUIRED COMPONENTS Core Widgets PrintSupport)
target_compile_definitions(appINGCgts PRIVATE QCUSTOMPLOT_USE_OPENGL)
target_link_libraries(appINGCgts PRIVATE Qt6::Gui Qt6::Widgets Qt6::PrintSupport)

# Добавляем иконку приложения
set_target_properties(appINGCgts PROPERTIES
    QT_ANDROID_PACKAGE_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/android"
)

if(ANDROID)
    # Минимальный API
    set(ANDROID_MIN_SDK_VERSION 21)

    # Разрешения
    set(ANDROID_PERMISSIONS
        android.permission.INTERNET
        android.permission.ACCESS_NETWORK_STATE
    )
    # Разрешить HTTP
    set(ANDROID_APPLICATION_ATTRIBUTES "android:usesCleartextTraffic=\"true\"")

    # Добавляем OpenSSL
    set(ANDROID_SDK_ROOT $ENV{ANDROID_HOME})
    set(OPENSSL_ANDROID_DIR "${ANDROID_SDK_ROOT}/android_openssl-master/ssl_3")
    message(STATUS "Path to OpenSSL Android: ${OPENSSL_ANDROID_DIR}")

    set(OPENSSL_INCLUDE_DIR "${OPENSSL_ANDROID_DIR}/include")
    if(ANDROID_ABI STREQUAL "arm64-v8a")
        set(OPENSSL_LIB_DIR "${OPENSSL_ANDROID_DIR}/arm64-v8a")
        set(SSL_LIB_PATH "${OPENSSL_LIB_DIR}/libssl.a")
        set(CRYPTO_LIB_PATH "${OPENSSL_LIB_DIR}/libcrypto.a")
    elseif (ANDROID_ABI STREQUAL "armeabi-v7a")
        set(OPENSSL_LIB_DIR "${OPENSSL_ANDROID_DIR}/armeabi-v7a")
        set(SSL_LIB_PATH "${OPENSSL_LIB_DIR}/libssl.a")
        set(CRYPTO_LIB_PATH "${OPENSSL_LIB_DIR}/libcrypto.a")
    endif()

    # Добавляем директорию с библиотеками
    link_directories(${OPENSSL_LIB_DIR})

    # Связываем библиотеки с вашей целью (target)
    target_include_directories(appINGCgts PRIVATE ${OPENSSL_INCLUDE_DIR})
    target_link_libraries(appINGCgts PRIVATE
        ${SSL_LIB_PATH}
        ${CRYPTO_LIB_PATH}
    )
endif()

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(appINGCgts PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.appINGCgts
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

include(GNUInstallDirs)
install(TARGETS appINGCgts
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
