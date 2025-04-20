package com.foo.foo

import android.graphics.Color
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.SystemBarStyle
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.runtime.getValue
import androidx.compose.runtime.setValue
import com.foo.foo.ui.theme.MyApplicationTheme

import foo.module.FooAPIClient

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        skip.foundation.ProcessInfo.launch(this)

        enableEdgeToEdge()
        setContent {
            MyApplicationTheme {
                Scaffold(modifier = Modifier.fillMaxSize()) { innerPadding ->
                    HelloWorld(Modifier.padding(innerPadding))
                }
            }
        }
    }
}

@Composable
fun HelloWorld(modifier: Modifier = Modifier) {
    var isLoggedIn by remember { mutableStateOf(false) }
    val apiClient = FooAPIClient.create()
    apiClient.apiKey = "0602UmYyQqztIfPV"
    Column(modifier = modifier) {
        AsyncButton(
            enabled = !isLoggedIn,
            action = {
                apiClient.loginWithSMS(
                    with = "223345999",
                    prefix = "+34",
                    countryCode = "ES",
                )
                val response = apiClient.checkConfirmationSMSCode(
                    with = "223345999",
                    prefix = "+34",
                    countryCode = "ES",
                    confirmationCode = "123456"
                )
                apiClient.authToken = response.customer.customerToken
                isLoggedIn = true
            }
        ) {
            Text("Log in")
        }

        AsyncButton(
            enabled = isLoggedIn,
            action = {
                apiClient.logOut()
                isLoggedIn = false
            }
        ) {
            Text("Log out")
        }
    }
}