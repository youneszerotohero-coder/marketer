<?php

namespace Tests\Feature;

use App\Models\User;
use App\Notifications\ResetPasswordNotification;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Notification;
use Tests\TestCase;

class ForgotPasswordTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Test requesting a reset code successfully for a valid marketer user.
     */
    public function test_send_reset_code_successfully_for_valid_marketer(): void
    {
        Notification::fake();

        $user = User::factory()->create([
            'email' => 'marketer@example.com',
            'role' => 'marketer',
        ]);

        $response = $this->postJson('/api/auth/forgot-password', [
            'email' => 'marketer@example.com',
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'status' => 'success',
                'message' => 'Code de réinitialisation envoyé avec succès à votre adresse e-mail.'
            ]);

        $this->assertDatabaseHas('password_reset_tokens', [
            'email' => 'marketer@example.com',
        ]);

        $token = DB::table('password_reset_tokens')
            ->where('email', 'marketer@example.com')
            ->value('token');

        $this->assertNotNull($token);
        $this->assertEquals(6, strlen($token));

        Notification::assertSentOnDemand(
            ResetPasswordNotification::class,
            function ($notification, $channels, $notifiable) use ($token, $user) {
                // Verify the mail representation doesn't throw errors
                $mailMessage = $notification->toMail($user);
                $this->assertNotNull($mailMessage);
                
                return $notifiable->routes['mail'] === 'marketer@example.com' && $notification->token === $token;
            }
        );
    }

    /**
     * Test requesting a reset code fails if email doesn't exist.
     */
    public function test_send_reset_code_fails_for_non_existent_email(): void
    {
        $response = $this->postJson('/api/auth/forgot-password', [
            'email' => 'nonexistent@example.com',
        ]);

        $response->assertStatus(404)
            ->assertJson([
                'status' => 'error',
                'message' => 'Aucun utilisateur trouvé avec cette adresse e-mail.'
            ]);

        $this->assertDatabaseMissing('password_reset_tokens', [
            'email' => 'nonexistent@example.com',
        ]);
    }

    /**
     * Test requesting a reset code fails if the user is not a marketer.
     */
    public function test_send_reset_code_fails_for_non_marketer(): void
    {
        $user = User::factory()->create([
            'email' => 'admin@example.com',
            'role' => 'admin',
        ]);

        $response = $this->postJson('/api/auth/forgot-password', [
            'email' => 'admin@example.com',
        ]);

        $response->assertStatus(403)
            ->assertJson([
                'status' => 'error',
                'message' => 'Accès non autorisé. Seuls les marketers peuvent réinitialiser leur mot de passe depuis cet endpoint.'
            ]);

        $this->assertDatabaseMissing('password_reset_tokens', [
            'email' => 'admin@example.com',
        ]);
    }

    /**
     * Test resetting password successfully with correct OTP code and strong password.
     */
    public function test_reset_password_successfully_with_valid_code(): void
    {
        $user = User::factory()->create([
            'email' => 'marketer@example.com',
            'role' => 'marketer',
            'password' => Hash::make('OldPassword123!'),
        ]);

        DB::table('password_reset_tokens')->insert([
            'email' => 'marketer@example.com',
            'token' => '123456',
            'created_at' => now(),
        ]);

        $response = $this->postJson('/api/auth/reset-password', [
            'email' => 'marketer@example.com',
            'token' => '123456',
            'password' => 'NewPassword123!',
            'password_confirmation' => 'NewPassword123!',
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'status' => 'success',
                'message' => 'Votre mot de passe a été réinitialisé avec succès.'
            ]);

        $user->refresh();
        $this->assertTrue(Hash::check('NewPassword123!', $user->password));

        $this->assertDatabaseMissing('password_reset_tokens', [
            'email' => 'marketer@example.com',
        ]);
    }

    /**
     * Test resetting password fails if password requirements are not met (weak password).
     */
    public function test_reset_password_fails_with_weak_password(): void
    {
        $user = User::factory()->create([
            'email' => 'marketer@example.com',
            'role' => 'marketer',
        ]);

        DB::table('password_reset_tokens')->insert([
            'email' => 'marketer@example.com',
            'token' => '123456',
            'created_at' => now(),
        ]);

        // Weak password (e.g. no symbols, no mixed case, or less than 8 chars)
        $weakPasswords = [
            'weak', // too short, no mix, no symbols
            'Weakpassword123', // missing symbols
            'weakpassword123!', // missing uppercase
            'WEAKPASSWORD123!', // missing lowercase
            'WeakPassword!', // missing numbers
        ];

        foreach ($weakPasswords as $weakPassword) {
            $response = $this->postJson('/api/auth/reset-password', [
                'email' => 'marketer@example.com',
                'token' => '123456',
                'password' => $weakPassword,
                'password_confirmation' => $weakPassword,
            ]);

            $response->assertStatus(422)
                ->assertJson([
                    'status' => 'error',
                    'message' => 'Validation échouée.'
                ]);
        }
    }

    /**
     * Test resetting password fails if token is incorrect.
     */
    public function test_reset_password_fails_with_incorrect_code(): void
    {
        $user = User::factory()->create([
            'email' => 'marketer@example.com',
            'role' => 'marketer',
        ]);

        DB::table('password_reset_tokens')->insert([
            'email' => 'marketer@example.com',
            'token' => '123456',
            'created_at' => now(),
        ]);

        $response = $this->postJson('/api/auth/reset-password', [
            'email' => 'marketer@example.com',
            'token' => '654321', // wrong code
            'password' => 'NewPassword123!',
            'password_confirmation' => 'NewPassword123!',
        ]);

        $response->assertStatus(400)
            ->assertJson([
                'status' => 'error',
                'message' => 'Le code de réinitialisation est incorrect.'
            ]);
    }

    /**
     * Test resetting password fails if token has expired (> 15 minutes).
     */
    public function test_reset_password_fails_with_expired_code(): void
    {
        $user = User::factory()->create([
            'email' => 'marketer@example.com',
            'role' => 'marketer',
        ]);

        // Insert token created 16 minutes ago
        DB::table('password_reset_tokens')->insert([
            'email' => 'marketer@example.com',
            'token' => '123456',
            'created_at' => now()->subMinutes(16),
        ]);

        $response = $this->postJson('/api/auth/reset-password', [
            'email' => 'marketer@example.com',
            'token' => '123456',
            'password' => 'NewPassword123!',
            'password_confirmation' => 'NewPassword123!',
        ]);

        $response->assertStatus(400)
            ->assertJson([
                'status' => 'error',
                'message' => 'Le code de réinitialisation a expiré (limite de 15 minutes).'
            ]);

        // The expired token should be deleted
        $this->assertDatabaseMissing('password_reset_tokens', [
            'email' => 'marketer@example.com',
        ]);
    }

    /**
     * Test verification of code succeeds with correct details.
     */
    public function test_verify_code_successfully_with_valid_details(): void
    {
        $user = User::factory()->create([
            'email' => 'marketer@example.com',
            'role' => 'marketer',
        ]);

        DB::table('password_reset_tokens')->insert([
            'email' => 'marketer@example.com',
            'token' => '123456',
            'created_at' => now(),
        ]);

        $response = $this->postJson('/api/auth/verify-code', [
            'email' => 'marketer@example.com',
            'token' => '123456',
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'status' => 'success',
                'message' => 'Code de validation correct.'
            ]);
    }

    /**
     * Test verification fails with incorrect code.
     */
    public function test_verify_code_fails_with_incorrect_details(): void
    {
        $user = User::factory()->create([
            'email' => 'marketer@example.com',
            'role' => 'marketer',
        ]);

        DB::table('password_reset_tokens')->insert([
            'email' => 'marketer@example.com',
            'token' => '123456',
            'created_at' => now(),
        ]);

        $response = $this->postJson('/api/auth/verify-code', [
            'email' => 'marketer@example.com',
            'token' => '654321', // wrong code
        ]);

        $response->assertStatus(400)
            ->assertJson([
                'status' => 'error',
                'message' => 'Le code de réinitialisation est incorrect.'
            ]);
    }

    /**
     * Test verification fails with expired code (> 15 minutes).
     */
    public function test_verify_code_fails_with_expired_token(): void
    {
        $user = User::factory()->create([
            'email' => 'marketer@example.com',
            'role' => 'marketer',
        ]);

        DB::table('password_reset_tokens')->insert([
            'email' => 'marketer@example.com',
            'token' => '123456',
            'created_at' => now()->subMinutes(16), // expired
        ]);

        $response = $this->postJson('/api/auth/verify-code', [
            'email' => 'marketer@example.com',
            'token' => '123456',
        ]);

        $response->assertStatus(400)
            ->assertJson([
                'status' => 'error',
                'message' => 'Le code de réinitialisation a expiré (limite de 15 minutes).'
            ]);

        // The expired token should be deleted
        $this->assertDatabaseMissing('password_reset_tokens', [
            'email' => 'marketer@example.com',
        ]);
    }
}
