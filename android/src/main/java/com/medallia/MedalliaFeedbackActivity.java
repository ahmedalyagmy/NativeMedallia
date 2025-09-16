package com.medallia;

import android.app.Activity;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;
import android.graphics.Color;
import android.graphics.Typeface;
import android.view.Gravity;
import android.widget.ScrollView;

import org.json.JSONObject;

public class MedalliaFeedbackActivity extends Activity {
    private static final String TAG = "MedalliaFeedback";
    private String username;
    private String password;
    private String medalliaToken;
    private String surveyId;
    
    private EditText feedbackEditText;
    private EditText ratingEditText;
    private Button submitButton;
    private Button cancelButton;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        
        // استرجاع البيانات من Intent
        Intent intent = getIntent();
        username = intent.getStringExtra("username");
        password = intent.getStringExtra("password");
        medalliaToken = intent.getStringExtra("medalliaToken");
        surveyId = intent.getStringExtra("surveyId");
        
        Log.d(TAG, "Creating Medallia feedback form with username: " + username);
        
        setupUI();
    }

    private void setupUI() {
        // إنشاء التخطيط الرئيسي
        ScrollView scrollView = new ScrollView(this);
        LinearLayout mainLayout = new LinearLayout(this);
        mainLayout.setOrientation(LinearLayout.VERTICAL);
        mainLayout.setPadding(40, 40, 40, 40);
        mainLayout.setBackgroundColor(Color.WHITE);

        // عنوان النموذج
        TextView titleTextView = new TextView(this);
        titleTextView.setText("تقييم الخدمة");
        titleTextView.setTextSize(24);
        titleTextView.setTextColor(Color.BLACK);
        titleTextView.setTypeface(null, Typeface.BOLD);
        titleTextView.setGravity(Gravity.CENTER);
        titleTextView.setPadding(0, 0, 0, 30);
        mainLayout.addView(titleTextView);

        // معلومات المستخدم
        if (username != null && !username.isEmpty()) {
            TextView userInfoTextView = new TextView(this);
            userInfoTextView.setText("المستخدم: " + username);
            userInfoTextView.setTextSize(16);
            userInfoTextView.setTextColor(Color.GRAY);
            userInfoTextView.setPadding(0, 0, 0, 20);
            mainLayout.addView(userInfoTextView);
        }

        // حقل التقييم
        TextView ratingLabel = new TextView(this);
        ratingLabel.setText("التقييم (1-5):");
        ratingLabel.setTextSize(16);
        ratingLabel.setTextColor(Color.BLACK);
        ratingLabel.setPadding(0, 0, 0, 10);
        mainLayout.addView(ratingLabel);

        ratingEditText = new EditText(this);
        ratingEditText.setHint("أدخل تقييمك من 1 إلى 5");
        ratingEditText.setInputType(android.text.InputType.TYPE_CLASS_NUMBER);
        ratingEditText.setBackgroundColor(Color.WHITE);
        ratingEditText.setPadding(15, 15, 15, 15);
        ratingEditText.setTextSize(16);
        mainLayout.addView(ratingEditText);

        // حقل التعليق
        TextView feedbackLabel = new TextView(this);
        feedbackLabel.setText("التعليق:");
        feedbackLabel.setTextSize(16);
        feedbackLabel.setTextColor(Color.BLACK);
        feedbackLabel.setPadding(0, 20, 0, 10);
        mainLayout.addView(feedbackLabel);

        feedbackEditText = new EditText(this);
        feedbackEditText.setHint("اكتب تعليقك هنا...");
        feedbackEditText.setMinLines(4);
        feedbackEditText.setMaxLines(8);
        feedbackEditText.setBackgroundColor(Color.WHITE);
        feedbackEditText.setPadding(15, 15, 15, 15);
        feedbackEditText.setTextSize(16);
        feedbackEditText.setGravity(Gravity.TOP);
        mainLayout.addView(feedbackEditText);

        // أزرار التحكم
        LinearLayout buttonLayout = new LinearLayout(this);
        buttonLayout.setOrientation(LinearLayout.HORIZONTAL);
        buttonLayout.setGravity(Gravity.CENTER);
        buttonLayout.setPadding(0, 30, 0, 0);

        // زر الإلغاء
        cancelButton = new Button(this);
        cancelButton.setText("إلغاء");
        cancelButton.setTextColor(Color.WHITE);
        cancelButton.setBackgroundColor(Color.RED);
        cancelButton.setPadding(30, 15, 30, 15);
        cancelButton.setTextSize(16);
        cancelButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                handleCancel();
            }
        });

        // زر الإرسال
        submitButton = new Button(this);
        submitButton.setText("إرسال");
        submitButton.setTextColor(Color.WHITE);
        submitButton.setBackgroundColor(Color.parseColor("#007AFF"));
        submitButton.setPadding(30, 15, 30, 15);
        submitButton.setTextSize(16);
        submitButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                handleSubmit();
            }
        });

        buttonLayout.addView(cancelButton);
        buttonLayout.addView(submitButton);

        mainLayout.addView(buttonLayout);
        scrollView.addView(mainLayout);
        setContentView(scrollView);
    }

    private void handleSubmit() {
        try {
            String rating = ratingEditText.getText().toString().trim();
            String feedback = feedbackEditText.getText().toString().trim();

            // التحقق من صحة البيانات
            if (rating.isEmpty()) {
                Toast.makeText(this, "يرجى إدخال التقييم", Toast.LENGTH_SHORT).show();
                return;
            }

            int ratingValue = Integer.parseInt(rating);
            if (ratingValue < 1 || ratingValue > 5) {
                Toast.makeText(this, "التقييم يجب أن يكون بين 1 و 5", Toast.LENGTH_SHORT).show();
                return;
            }

            // إنشاء JSON object للبيانات
            JSONObject formData = new JSONObject();
            formData.put("username", username);
            formData.put("rating", ratingValue);
            formData.put("feedback", feedback);
            formData.put("timestamp", System.currentTimeMillis());
            formData.put("medalliaToken", medalliaToken);
            formData.put("surveyId", surveyId);

            Log.d(TAG, "Form submitted with data: " + formData.toString());

            // إرسال النتيجة
            Intent resultIntent = new Intent();
            resultIntent.putExtra("result", formData.toString());
            setResult(Activity.RESULT_OK, resultIntent);
            finish();

        } catch (Exception e) {
            Log.e(TAG, "Error submitting form: " + e.getMessage());
            Toast.makeText(this, "حدث خطأ في إرسال النموذج", Toast.LENGTH_SHORT).show();
        }
    }

    private void handleCancel() {
        Log.d(TAG, "Form cancelled by user");
        
        Intent resultIntent = new Intent();
        resultIntent.putExtra("result", "cancelled");
        setResult(Activity.RESULT_CANCELED, resultIntent);
        finish();
    }

    @Override
    public void onBackPressed() {
        handleCancel();
    }
}
