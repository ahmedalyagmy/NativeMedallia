import { NativeModules, NativeEventEmitter } from 'react-native';

const { MedalliaNativeModule } = NativeModules;
const emitter = new NativeEventEmitter(MedalliaNativeModule);

export const addFormActionListener = (handler) => {
    const sub = emitter.addListener('MedalliaFormAction', handler);
    return () => sub.remove();
};

export const injectUserData = (username, password, medalliaToken, surveyId) =>
    MedalliaNativeModule.injectUserData(username, password, medalliaToken, surveyId);

export const showFeedbackForm = () => MedalliaNativeModule.showFeedbackForm();

export const handleNotification = (notificationData) =>
    MedalliaNativeModule.handleNotification(notificationData);

export default {
    addFormActionListener,
    injectUserData,
    showFeedbackForm,
    handleNotification,
};


