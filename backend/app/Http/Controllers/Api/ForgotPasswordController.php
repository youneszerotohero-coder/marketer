<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Http;
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

        // Send the code via Brevo HTTP API (avoids SMTP port restrictions)
        try {
            $brevoApiKey = env('BREVO_KEY', '');
            $fromEmail   = env('MAIL_FROM_ADDRESS', 'noreply@example.com');
            $fromName    = env('MAIL_FROM_NAME', 'Arbahi');

            $response = Http::withHeaders([
                'api-key'      => $brevoApiKey,
                'Content-Type' => 'application/json',
                'Accept'       => 'application/json',
            ])->post('https://api.brevo.com/v3/smtp/email', [
                'sender'     => ['name' => $fromName, 'email' => $fromEmail],
                'to'         => [['email' => $request->email]],
                'subject'    => 'Code de réinitialisation de mot de passe - Arbahi',
                'htmlContent' => '
                    <div style="font-family:Arial,sans-serif;max-width:480px;margin:0 auto;padding:24px;background:#fff;border-radius:12px">
                        <h2 style="color:#EA580C;margin-bottom:8px">Réinitialisation de mot de passe</h2>
                        <p>Bonjour,</p>
                        <p>Vous avez demandé la réinitialisation de votre mot de passe Arbahi.</p>
                        <p>Voici votre code de validation :</p>
                        <div style="background:#FFF7ED;border:2px solid #EA580C;border-radius:8px;padding:16px;text-align:center;margin:16px 0">
                            <span style="font-size:32px;font-weight:bold;color:#EA580C;letter-spacing:8px">' . $token . '</span>
                        </div>
                        <p style="color:#666;font-size:13px">Ce code est valide pendant <strong>15 minutes</strong>.</p>
                        <p style="color:#666;font-size:13px">Si vous n\'êtes pas à l\'origine de cette demande, ignorez cet e-mail.</p>
                        <hr style="border:none;border-top:1px solid #eee;margin:16px 0">
                        <p style="color:#aaa;font-size:12px;text-align:center">Arbahi &copy; ' . date('Y') . '</p>
                    </div>',
            ]);

            if ($response->failed()) {
                $errBody = $response->json();
                $errMsg  = $errBody['message'] ?? $response->body();
                return response()->json([
                    'status'  => 'error',
                    'message' => 'Erreur lors de l\'envoi de l\'e-mail : ' . $errMsg
                ], 500);
            }
        } catch (\Exception $e) {
            return response()->json([
                'status'  => 'error',
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
                    ->letters(),
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
