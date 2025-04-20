package com.foo.foo

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import androidx.compose.ui.unit.dp
import kotlinx.coroutines.launch

suspend fun performAction(
    action: suspend () -> Unit,
    onResult: (Result<Unit>) -> Unit
) {
    try {
        action()
        onResult(Result.Success(Unit))
    } catch (e: Exception) {
        onResult(Result.Failure(e))
    }
}

sealed class ButtonState {
    object Idle : ButtonState()
    object Loading : ButtonState()
}

sealed class Result<out T> {
    data class Success<out T>(val data: T) : Result<T>()
    data class Failure(val exception: Throwable) : Result<Nothing>()
}

@Composable
fun ErrorAlert(error: Throwable, onDismiss: () -> Unit) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Error") },
        text = { Text(error.localizedMessage ?: "Unknown error") },
        confirmButton = {
            TextButton(onClick = onDismiss) {
                Text("OK")
            }
        }
    )
}

@Composable
fun AsyncButton(
    enabled: Boolean = true,
    action: suspend () -> Unit = {},
    label: @Composable () -> Unit = {}
) {
    var state by remember { mutableStateOf<ButtonState>(ButtonState.Idle) }
    var error by remember { mutableStateOf<Throwable?>(null) }
    val coroutineScope = rememberCoroutineScope()
    Button(
        onClick = {
            state = ButtonState.Loading
            coroutineScope.launch {
                performAction(action) { result ->
                    when (result) {
                        is Result.Success -> {}
                        is Result.Failure -> error = result.exception
                    }
                    state = ButtonState.Idle
                }
            }
        },
        enabled = enabled && state != ButtonState.Loading && error == null
    ) {
        Box(contentAlignment = Alignment.Center) {
            if (state == ButtonState.Loading) {
                AsyncButtonLoadingView()
            } else {
                label()
            }
        }
    }

    error?.let {
        ErrorAlert(error = it, onDismiss = { error = null })
    }
}
@Composable
fun AsyncButtonLoadingView() {
    Row(verticalAlignment = Alignment.CenterVertically) {
        CircularProgressIndicator(modifier = Modifier.size(16.dp))
        Spacer(modifier = Modifier.width(8.dp))
        Text(text = "Loading...")
    }
}

@Preview
@Composable
fun PreviewAsyncButton(){
    AsyncButton(
        label = {
            Text("Async button")
        }
    )
}