import React, { useEffect } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, Alert } from 'react-native';
import MedalliaHelper from '../utils/MedalliaHelper';

const MedalliaExample = () => {
    useEffect(() => {
        // إعداد callback للـ response
        MedalliaHelper.setOnFormAction((data) => {
            if (data.action === 'submit') {
                Alert.alert('تم الإرسال', 'تم إرسال التقييم بنجاح');
                console.log('Form submitted:', data.formData);
            } else if (data.action === 'cancel') {
                Alert.alert('تم الإلغاء', 'تم إلغاء التقييم');
                console.log('Form cancelled');
            }
        });

        return () => {
            MedalliaHelper.cleanup();
        };
    }, []);

    const handleShowFeedback = async () => {
        const result = await MedalliaHelper.showFeedback(
            'username123',           // username
            'password123',           // password
            'medallia-token-123',    // medalliaToken
            'survey-id-456'          // surveyId
        );

        if (!result.success) {
            Alert.alert('خطأ', result.error);
        }
    };

    const handleTestNotification = async () => {
        const notificationData = {
            type: 'feedback_request',
            username: 'username123',
            password: 'password123',
            medalliaToken: 'medallia-token-123',
            surveyId: 'survey-id-456'
        };

        const result = await MedalliaHelper.handleNotification(notificationData);

        if (!result.success) {
            Alert.alert('خطأ', result.error);
        }
    };

    return (
        <View style={styles.container}>
            <Text style={styles.title}>Medallia Native Example</Text>

            <TouchableOpacity style={styles.button} onPress={handleShowFeedback}>
                <Text style={styles.buttonText}>عرض نموذج التقييم</Text>
            </TouchableOpacity>

            <TouchableOpacity
                style={[styles.button, styles.secondaryButton]}
                onPress={handleTestNotification}
            >
                <Text style={styles.buttonText}>اختبار الإشعار</Text>
            </TouchableOpacity>
        </View>
    );
};

const styles = StyleSheet.create({
    container: {
        flex: 1,
        justifyContent: 'center',
        alignItems: 'center',
        padding: 20,
        backgroundColor: '#f5f5f5',
    },
    title: {
        fontSize: 24,
        fontWeight: 'bold',
        marginBottom: 30,
        color: '#333',
    },
    button: {
        backgroundColor: '#007AFF',
        paddingHorizontal: 30,
        paddingVertical: 15,
        borderRadius: 8,
        marginBottom: 15,
        minWidth: 200,
        alignItems: 'center',
    },
    secondaryButton: {
        backgroundColor: '#34C759',
    },
    buttonText: {
        color: '#fff',
        fontSize: 16,
        fontWeight: 'bold',
    },
});

export default MedalliaExample;
