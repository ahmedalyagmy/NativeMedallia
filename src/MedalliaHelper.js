import { NativeModules, NativeEventEmitter } from 'react-native';

const { MedalliaNativeModule } = NativeModules;

class MedalliaHelper {
    constructor() {
        this.eventEmitter = new NativeEventEmitter(MedalliaNativeModule);
        this.setupEventListeners();
    }

    setupEventListeners() {
        // الاستماع لأحداث الـ Native Module
        this.eventEmitter.addListener('MedalliaFormAction', (data) => {
            console.log('Medallia Form Action:', data);
            this.onFormAction?.(data);
        });
    }

    // حقن البيانات وعرض النموذج
    async showFeedback(username, password, medalliaToken, surveyId) {
        try {
            // حقن البيانات
            await MedalliaNativeModule.injectUserData(username, password, medalliaToken, surveyId);

            // عرض النموذج
            await MedalliaNativeModule.showFeedbackForm();

            return { success: true };
        } catch (error) {
            console.error('Error showing feedback:', error);
            return { success: false, error: error.message };
        }
    }

    // التعامل مع الـ notifications
    async handleNotification(notificationData) {
        try {
            await MedalliaNativeModule.handleNotification(notificationData);
            return { success: true };
        } catch (error) {
            console.error('Error handling notification:', error);
            return { success: false, error: error.message };
        }
    }

    // إعداد callback للـ response
    setOnFormAction(callback) {
        this.onFormAction = callback;
    }

    // تنظيف الـ listeners
    cleanup() {
        this.eventEmitter.removeAllListeners('MedalliaFormAction');
    }
}

export default new MedalliaHelper();
