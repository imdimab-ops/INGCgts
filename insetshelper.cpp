#include "insetshelper.h"

InsetsHelper::InsetsHelper(QObject *parent)
    : QObject{parent}
{

}

InsetsHelper::~InsetsHelper()
{

}

InsetsHelper *InsetsHelper::getInstance(QQmlEngine *engine, QJSEngine *jsEngine)
{
    Q_UNUSED(jsEngine)
    static InsetsHelper instance;
    // qDebug() << "Singleton adr:" << &instance;

    //если порядок удаления наружен приложение при закрытии завершается с ошибкой!
    //делаем только так
    engine->setObjectOwnership(&instance, QQmlEngine::CppOwnership); //Qt не удаляет объект раньше удаления Qml
    return &instance;
}

jfloat InsetsHelper::getDensity(const QJniObject &activity)
{
    // Получаем Resources
    QJniObject resources = activity.callObjectMethod(
        "getResources",
        "()Landroid/content/res/Resources;"
        );
    if (!resources.isValid()) return 0;

    // Получаем DisplayMetrics
    QJniObject metrics = resources.callObjectMethod(
        "getDisplayMetrics",
        "()Landroid/util/DisplayMetrics;"
        );
    if (!metrics.isValid()) return 0;

    // Получаем density (плотность пиксела)
    jfloat density = metrics.getField<jfloat>("density");


    return density;
}

int InsetsHelper::getStatusBarHeight() {
    QJniObject activity = QJniObject::callStaticObjectMethod(
        "org/qtproject/qt/android/QtNative",
        "activity",
        "()Landroid/app/Activity;"
        );
    if (!activity.isValid()) return 0;

    // Получаем Window и DecorView
    QJniObject window = activity.callObjectMethod("getWindow", "()Landroid/view/Window;");
    if (!window.isValid()) return 0;

    QJniObject decorView = window.callObjectMethod("getDecorView", "()Landroid/view/View;");
    if (!decorView.isValid()) return 0;

    // Получаем WindowInsets
    QJniObject insets = decorView.callObjectMethod(
        "getRootWindowInsets",
        "()Landroid/view/WindowInsets;"
        );
    if (!insets.isValid()) return 0;


    if (QJniObject::isClassAvailable("android/view/WindowInsets$Type")) {

        // Проверяем доступность DisplayCutout (API 28+)
        QJniObject cutout = insets.callObjectMethod(
            "getDisplayCutout",
            "()Landroid/view/DisplayCutout;"
            );
        if (cutout.isValid()) {
            jint pixels = cutout.callMethod<jint>("getSafeInsetTop", "()I");
            return static_cast<int>(pixels / getDensity(activity)); // Масштабируем
        }
    }


    // // Альтернативный способ через системный ресурс, если WindowInsets не сработал
    // int resourceId = resources.callMethod<jint>(
    //     "getIdentifier",
    //     "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)I",
    //     QJniObject::fromString("status_bar_height").object(),
    //     QJniObject::fromString("dimen").object(),
    //     QJniObject::fromString("android").object()
    //     );

    // // Получаем значение ресурса в пикселях
    // if (resourceId > 0) {
    //     jint pixels = resources.callMethod<jint>("getDimensionPixelSize", "(I)I", resourceId);

    //     // Масштабируем согласно плотности экрана
    //     return static_cast<int>(pixels / density);
    // }

    return 0;
}

int InsetsHelper::getNavigationBarHeight() {

    QJniObject activity = QJniObject::callStaticObjectMethod(
        "org/qtproject/qt/android/QtNative",
        "activity",
        "()Landroid/app/Activity;"
        );
    if (!activity.isValid()) return 0;

    // Получаем Window и DecorView
    QJniObject window = activity.callObjectMethod("getWindow", "()Landroid/view/Window;");
    if (!window.isValid()) return 0;

    QJniObject decorView = window.callObjectMethod("getDecorView", "()Landroid/view/View;");
    if (!decorView.isValid()) return 0;

    // Получаем WindowInsets
    QJniObject insets = decorView.callObjectMethod(
        "getRootWindowInsets",
        "()Landroid/view/WindowInsets;"
        );
    if (!insets.isValid()) return 0;

    if (QJniObject::isClassAvailable("android/view/WindowInsets$Type")) {
        jint navigationBars = 2; // WindowInsets.Type.navigationBars()
        QJniObject navBarInsets = insets.callObjectMethod(
            "getInsets",
            "(I)Landroid/graphics/Insets;",
            navigationBars
            );
        if (navBarInsets.isValid()) {
            jint pixels = navBarInsets.getField<jint>("bottom");
            return static_cast<int>(pixels / getDensity(activity)); // Масштабируем
        }
    }

    // // Альтернативный способ через системный ресурс, если WindowInsets не сработал
    // int resourceId = resources.callMethod<jint>(
    //     "getIdentifier",
    //     "(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)I",
    //     QJniObject::fromString("navigation_bar_height").object(),
    //     QJniObject::fromString("dimen").object(),
    //     QJniObject::fromString("android").object()
    //     );

    // // Получаем значение ресурса в пикселях
    // if (resourceId > 0) {
    //     jint pixels = resources.callMethod<jint>("getDimensionPixelSize", "(I)I", resourceId);

    //     // Масштабируем согласно плотности экрана
    //     return static_cast<int>(pixels / density);
    // }

    return 0;

}

void InsetsHelper::lockPortrait()
{
    QJniObject activity = QJniObject::callStaticObjectMethod(
        "org/qtproject/qt/android/QtNative",
        "activity",
        "()Landroid/app/Activity;"
        );

    if (activity.isValid()) {
        // SCREEN_ORIENTATION_PORTRAIT = 1
        // SCREEN_ORIENTATION_SENSOR = 4 (разрешает все ориентации)
        // или SCREEN_ORIENTATION_UNSPECIFIED = -1 (по умолчанию)
        activity.callMethod<void>(
            "setRequestedOrientation",
            "(I)V",
            1  // или -1, в зависимости от нужного поведения
            );
    }
}

void InsetsHelper::unlockOrientation()
{
    QJniObject activity = QJniObject::callStaticObjectMethod(
        "org/qtproject/qt/android/QtNative",
        "activity",
        "()Landroid/app/Activity;"
        );

    if (activity.isValid()) {
        // SCREEN_ORIENTATION_PORTRAIT = 1
        // SCREEN_ORIENTATION_SENSOR = 4 (разрешает все ориентации)
        // или SCREEN_ORIENTATION_UNSPECIFIED = -1 (по умолчанию)
        activity.callMethod<void>(
            "setRequestedOrientation",
            "(I)V",
            4  // или -1, в зависимости от нужного поведения
            );
    }
}

void InsetsHelper::setImmersiveMode(const bool &enable)
{
    // Получаем Activity
    QJniObject activity = QJniObject::callStaticObjectMethod(
        "org/qtproject/qt/android/QtNative",
        "activity",
        "()Landroid/app/Activity;"
        );

    // Для API 30+ (рекомендуемый способ)
    if (activity.isValid()) {
        QJniObject window = activity.callObjectMethod(
            "getWindow",
            "()Landroid/view/Window;"
            );
        QJniObject decorView = window.callObjectMethod(
            "getDecorView",
            "()Landroid/view/View;"
            );
        QJniObject insetsController = decorView.callObjectMethod(
            "getWindowInsetsController",
            "()Landroid/view/WindowInsetsController;"
            );

        if (insetsController.isValid() && enable) {
            insetsController.callMethod<void>(
                "hide",
                "(I)V",
                7 | 8 | 9 // systemBars() | displayCutout()
                );
            insetsController.callMethod<void>(
                "setSystemBarsBehavior",
                "(I)V",
                1 // BEHAVIOR_SHOW_BARS_BY_SWIPE
                );
        }
        if (insetsController.isValid() && !enable) {
            //Очищаем фокус
            decorView.callMethod<void>(
                "clearFocus",
                "()V"
                );
            //Показываем статус бар
            insetsController.callMethod<void>(
                "show",
                "(I)V",
                7 | 8 | 9 // systemBars() | displayCutout()
                );
            insetsController.callMethod<void>(
                "setSystemBarsBehavior",
                "(I)V",
                0 // BEHAVIOR_SHOW_BARS_BY_SWIPE
                );

            //Скрываем клавиатуру
            QJniObject inputMethodManager = activity.callObjectMethod(
                "getSystemService",
                "(Ljava/lang/String;)Ljava/lang/Object;",
                QJniObject::fromString("input_method").object()
                );
            if (inputMethodManager.isValid()) {
                inputMethodManager.callMethod<jboolean>(
                    "hideSoftInputFromWindow",
                    "(Landroid/os/IBinder;I)Z",
                    decorView.callMethod<jobject>(
                        "getWindowToken",
                        "()Landroid/os/IBinder;"
                        ),
                    0
                    );
            }
        }
    }
    qDebug() << Q_FUNC_INFO;
}

void InsetsHelper::vibrateAndroid(const int &milliseconds)
{
    // Получаем контекст приложения
    QJniObject context = QNativeInterface::QAndroidApplication::context();
    if (!context.isValid()) {
        return;
    }

    // Получаем системный сервис вибрации
    QJniObject vibratorService = QJniObject::getStaticObjectField(
        "android/content/Context",
        "VIBRATOR_SERVICE",
        "Ljava/lang/String;"
        );

    QJniObject vibrator = context.callObjectMethod(
        "getSystemService",
        "(Ljava/lang/String;)Ljava/lang/Object;",
        vibratorService.object()
        );

    if (vibrator.isValid()) {
        QJniObject effect = QJniObject::callStaticObjectMethod(
            "android/os/VibrationEffect",
            "createOneShot",
            "(JI)Landroid/os/VibrationEffect;",
            static_cast<jlong>(milliseconds),
            -1  // DEFAULT_AMPLITUDE
            );

        vibrator.callMethod<void>(
            "vibrate",
            "(Landroid/os/VibrationEffect;)V",
            effect.object()
            );
    }
}
