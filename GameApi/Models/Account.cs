using System.ComponentModel.DataAnnotations;

namespace GameApi.Models;

public class Account
{
    public int Id { get; set; }

    [Required]
    [StringLength(50, MinimumLength = 3)]
    public string Username { get; set; } = string.Empty;

    [Required]
    [StringLength(255)]
    public string PasswordHash { get; set; } = string.Empty;

    public DateTime CreatedAt { get; set; }

    public ICollection<Character> Characters { get; set; } = new List<Character>();
}
