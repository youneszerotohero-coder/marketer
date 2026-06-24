<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Notifications\ResetPasswordNotification;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Notification;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rules\Password;

class ForgotPasswordController extends Controller
{
    /**
     * Send a 6-digit reset code to the user's email.
     */
    public function sendResetLink(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'email' => ['required', 'email'],
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'message' => 'Validation échouée.',
                'errors' => $validator->errors()
            ], 422);
        }

        $user = User::where('email', $request->email)->first();

        // Security check: Only allow existing users with role 'marketer' to request reset code
        if (!$user) {
            return response()->json([
                'status' => 'error',
                'message' => 'Aucun utilisateur trouvé avec cette adresse e-mail.'
            ], 404);
        }

        if ($user->role !== 'marketer') {
            return response()->json([
                'status' => 'error',
                'message' => 'Accès non autorisé. Seuls les marketers peuvent réinitialiser leur mot de passe depuis cet endpoint.'
            ], 403);
        }

        // Generate a 6-digit random code
        $token = sprintf('%06d', random_int(100000, 999999));

        // Store or update the reset token in the database
        DB::table('password_reset_tokens')->updateOrInsert(
            ['email' => $request->email],
            [
                'token' => $token,
                'created_at' => now(),
            ]
        );

        // Send the notification using the default mailer
        try {
            Notification::route('mail', $request->email)->notify(new ResetPasswordNotification($token));
        } catch (\Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => 'Erreur lors de l\'envoi de l\'e-mail : ' . $e->getMessage()
            ], 500);
        }

        return response()->json([
            'status' => 'success',
            'message' => 'Code de réinitialisation envoyé avec succès à votre adresse e-mail.'
        ], 200);
    }

    /**
     * Reset the user's password using the verified 6-digit code.
     */
    public function resetPassword(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'email' => ['required', 'email'],
            'token' => ['required', 'string', 'size:6'],
            'password' => [
                'required',
                'string',
                Password::min(8)
                    ->letters()
                    ->mixedCase()
                    ->numbers()
                    ->symbols(),
                'confirmed'
            ],
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'message' => 'Validation échouée.',
                'errors' => $validator->errors()
            ], 422);
        }

        $record = DB::table('password_reset_tokens')
            ->where('email', $request->email)
            ->first();

        if (!$record) {
            return response()->json([
                'status' => 'error',
                'message' => 'Aucune demande de réinitialisation trouvée pour cet e-mail.'
            ], 400);
        }

        // Check if the token matches
        if ($record->token !== $request->token) {
            return response()->json([
                'status' => 'error',
                'message' => 'Le code de réinitialisation est incorrect.'
            ], 400);
        }

        // Check if token has expired (15 minutes limit)
        $createdAt = Carbon::parse($record->created_at);
        if ($createdAt->addMinutes(15)->isPast()) {
            // Delete expired token for security
            DB::table('password_reset_tokens')->where('email', $request->email)->delete();

            return response()->json([
                'status' => 'error',
                'message' => 'Le code de réinitialisation a expiré (limite de 15 minutes).'
            ], 400);
        }

        // Update user password
        $user = User::where('email', $request->email)->first();
        if (!$user) {
            return response()->json([
                'status' => 'error',
                'message' => 'Utilisateur introuvable.'
            ], 404);
        }

        $user->password = Hash::make($request->password);
        $user->save();

        // Delete the verified token
        DB::table('password_reset_tokens')->where('email', $request->email)->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'Votre mot de passe a été réinitialisé avec succès.'
        ], 200);
    }

    /**
     * Verify the 6-digit reset code without updating password.
     */
    public function verifyCode(Request $request): JsonResponse
    {
        $validator = Validator::make($request->all(), [
            'email' => ['required', 'email'],
            'token' => ['required', 'string', 'size:6'],
        ]);

        if ($validator->fails()) {
            return response()->json([
                'status' => 'error',
                'message' => 'Validation échouée.',
                'errors' => $validator->errors()
            ], 422);
        }

        $record = DB::table('password_reset_tokens')
            ->where('email', $request->email)
            ->first();

        if (!$record) {
            return response()->json([
                'status' => 'error',
                'message' => 'Aucune demande de réinitialisation trouvée pour cet e-mail.'
            ], 400);
        }

        // Check if the token matches
        if ($record->token !== $request->token) {
            return response()->json([
                'status' => 'error',
                'message' => 'Le code de réinitialisation est incorrect.'
            ], 400);
        }

        // Check if token has expired (15 minutes limit)
        $createdAt = Carbon::parse($record->created_at);
        if ($createdAt->addMinutes(15)->isPast()) {
            // Delete expired token for security
            DB::table('password_reset_tokens')->where('email', $request->email)->delete();

            return response()->json([
                'status' => 'error',
                'message' => 'Le code de réinitialisation a expiré (limite de 15 minutes).'
            ], 400);
        }

        return response()->json([
            'status' => 'success',
            'message' => 'Code de validation correct.'
        ], 200);
    }
}
