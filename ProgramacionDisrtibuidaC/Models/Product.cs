using System.ComponentModel.DataAnnotations;

namespace ProgramacionDisrtibuidaC.Models
{
    public class Product
    {
        public int Id { get; set; }

        [Required]
        [StringLength(200, MinimumLength = 2)]
        [RegularExpression(@".*\S.*", ErrorMessage = "Name cannot contain only spaces.")]
        public string Name { get; set; } = string.Empty;

        [Range(
            typeof(decimal),
            "0.01",
            "99999999.99",
            ParseLimitsInInvariantCulture = true)]
        public decimal Price { get; set; }

        [Range(0, int.MaxValue)]
        public int Stock { get; set; }

        [Range(0, int.MaxValue)]
        public int Version { get; set; } = 0;
    }
}
